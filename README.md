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
| -r --ruby | override .ruby-version with specified version |
| --discard-changes | discard any local changes instead of stashing |
| --clobber | remove precompiled assets (force precompile) |
| --skip-migration | skip database migrations |
| --skip-precompile | skip precompiling of assets |

### helltop
A python script parsing hellpot logs and creating a toplist based on how much trash was eaten.

| options | description |
| ------- | ----------- |
| -h --help | show usage |
| -p --path | path to hellpot logs (default: current working directory) |
| -t --top | show top x results (default: 10) |
| -e --exclude | exclude IP(s) from results |

### move_locales
A python script which behaves similar to the old `manage:translations` command, adding missing strings to locale files and also removing them from upstream locales. Requires `en.json` in output dir.

| options | description |
| ------- | ----------- |
| -i --in | path to upstream locales |
| -o --out | path to new locales |
| -c --copy | Copies translations instead of moving them |

### toot_keeper
A python script checking english locale files in project dir for uses of "post" instead of "toot".

| options | description |
| ------- | ----------- |
| -p --path | path to source dir |
| -i --ignored-keys | keys to ignore |
