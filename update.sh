#!/bin/bash

# exit on non-zero exit code and pipefail
set -o errexit -o pipefail

# Require running as root
if [[ $EUID -ne 0 ]]; then
  echo "Script must be run as root"
  exit 2
fi

# check for getopt compatibility
# if exit code isn't 4, enhanced getopt is not available
# shellcheck disable=SC2251
! getopt --test > /dev/null
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
  echo 'Enhanced getopt not available'
  exit 1
fi

print_help()
{
  echo "Usage: update.sh [options]"
  echo
  echo "Options:"
  echo "-h, --help               print this help and exit"
  echo "-u, --user <user>        run commands as user"
  echo "-b, --branch <branch>    branch to pull [default: main]"
  echo "-d, --dir <dir>          dir where mastodon is installed"
  echo "-r, --ruby <version>     override .ruby-version with specified version"
  echo "--discard-changes        discard any local changes instead of stashing them"
  echo "--clobber                Remove precompiled assets before precompiling"
  echo "--skip-migration         skip database migrations"
  echo "--skip-precompile        skip precompiling assets"
}

BRANCH=main

OPTIONS=hu:b:d:r:
LONGOPTS=help,user:,branch:,dir:,ruby:,discard-changes,clobber,skip-migration,skip-precompile

# shellcheck disable=SC2251
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
# Check if arguments have been parsed successfully
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
  print_help
  exit 2
fi

# Read output of getopt
eval set -- "$PARSED"

# Read arguments
while true;do
  case "$1" in
    -h|--help)
      print_help
      exit;;
    -u|--user)
      MASTODONUSER="$2"
      shift 2;;
    -b|--branch)
      BRANCH="$2"
      shift 2;;
    -d|--dir)
      MASTODON_DIR="$2"
      shift 2;;
    -r|--ruby)
      RUBY_VERSION="$2"
      shift 2;;
    --discard-changes)
      DISCARD=true
      shift;;
    --clobber)
      CLOBBER=true
      shift;;
    --skip-migration)
      SKIP_MIGRATION=true
      shift;;
    --skip-precompile)
      SKIP_PRECOMPILE=true
      shift;;
    --)
      shift
      break;;
    *)
      echo "Parsing error"
      exit 3;;
  esac
done

# Check if parsed user exists
if ! id "$MASTODONUSER" &>/dev/null; then
  echo "User $MASTODONUSER not found"
  exit 2
fi

# Set MASTODON_DIR if not given
if [[ ! "$MASTODON_DIR" ]]; then
  # Default install directory
  if [ -d "/home/mastodon/live" ]; then
    MASTODON_DIR="/home/mastodon/live"
  # Default install directory on arch
  elif [ -d "/var/lib/mastodon" ]; then
    MASTODON_DIR="/var/lib/mastodon"
  # Some distros have a srv directory
  elif [ -d "/srv/mastodon" ]; then
    MASTODON_DIR="/srv/mastodon"
  else
    echo "Please specify where mastodon is installed with --dir"
    exit 2
  fi
fi

# Check that MASTODON_DIR exists
if [ ! -d "$MASTODON_DIR" ]; then
  echo "Mastodon directory not found"
  exit 2
fi

cd "$MASTODON_DIR"

# Check if remote exists and if not add it
if ! sudo -u "$MASTODONUSER" git config remote.polyam.url > /dev/null;then
  echo "Adding polyam remote..."
  sudo -u "$MASTODONUSER" git remote add polyam https://github.com/polyamspace/mastodon.git
fi

# Fetch and pull new code from remote
echo "Fetching new code..."
sudo -u "$MASTODONUSER" git fetch polyam

if [[ ! "$DISCARD" ]];then
  # Stash local changes. Safer than restore.
  sudo -u "$MASTODONUSER" git stash
else
  # discards any local changes
  sudo -u "$MASTODONUSER" git restore .
fi

# Switch to branch if it differs from current branch, otherwise pull updates
if [[ "$(sudo -u "$MASTODONUSER" git branch --show-current)" != "$BRANCH" ]]; then
  echo "Checking out polyam/$BRANCH..."
  sudo -u "$MASTODONUSER" git checkout polyam/"$BRANCH" -t
else
  echo "Pulling updates..."
  sudo -u "$MASTODONUSER" git pull polyam
fi

if [[ $RUBY_VERSION ]];then
  echo "Overriding ruby version with $RUBY_VERSION"
  echo "$RUBY_VERSION" > .ruby-version
fi

# corepack is no longer included in node package
# and has to be installed separately.
# That might make yarn unavailable after updating node,
# so install corepack when yarn can't be found.
if ! type "yarn" > /dev/null 2>&1; then
  echo "yarn not found. Installing corepack..."
  npm install -g corepack
fi

# Install dependencies
echo "Installing dependencies..."
sudo -u "$MASTODONUSER" bundle install && sudo -u "$MASTODONUSER" yarn install --immutable

# pre-deploy migration
if [[ ! "$SKIP_MIGRATION" ]];then
  echo "Running pre-deploy database migration..."
  sudo -u "$MASTODONUSER" RAILS_ENV=production SKIP_POST_DEPLOYMENT_MIGRATIONS=true bundle exec rails db:migrate
fi

# precompile assets
if [[ ! "$SKIP_PRECOMPILE" ]];then
  if [[ "$CLOBBER" ]]; then
    echo "Removing precompiled assets..."
    sudo -u "$MASTODONUSER" RAILS_ENV=production bundle exec rails assets:clobber
  fi

  echo "Precompiling assets... This might take a while"
  sudo -u "$MASTODONUSER" RAILS_ENV=production bundle exec rails assets:precompile
fi

# restart services
# If you copy this line make sure to add sudo in front of both commands
echo "Restarting Mastodon..."
systemctl reload mastodon-web && systemctl restart mastodon-{'sidekiq*',streaming}

# Clean cache
echo "Cleaning cache..."
sudo -u "$MASTODONUSER" RAILS_ENV=production ./bin/tootctl cache clear

# post-deploy migration
if [[ ! "$SKIP_MIGRATION" ]];then
  echo "Running post-deploy database migration..."
  sudo -u "$MASTODONUSER" RAILS_ENV=production bundle exec rails db:migrate
fi

echo "DONE!"
