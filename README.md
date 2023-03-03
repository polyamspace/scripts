# scripts

### update.sh
A script to update existing polyam-glitch installations.

| options | description |
| ------- | ----------- |
| -h --help | show usage |
| -u --user | set mastodon user (Required) |
| -b --branch | branch to pull from |
| -l --legacy | use openssl-legacy-provider node option. Required for openssl3 |
| -d --dir | set mastodon install directory |
| --discard-changes | discard any local changes instead of stashing |
| --clobber | remove precompiled assets (force precompile) |
| --skip-migration | skip database migrations |
| --skip-precompile | skip precompiling of assets |
