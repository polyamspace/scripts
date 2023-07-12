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

### helltop
A python script parsing hellpot logs and creating a toplist based on how much trash was eaten.

| options | description |
| ------- | ----------- |
| -h --help | show usage |
| -p --path | path to hellpot logs (default: current working directory) |
| -t --top | show top x results (default: 10) |
| -e --exclude | exclude IP(s) from results |
