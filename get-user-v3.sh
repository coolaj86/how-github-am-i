#!/bin/sh
set -e
set -u

# shellcheck disable=SC1090
# 1. Go to from https://github.com/settings/tokens
# 2. Put token into this ENV file
#    in the form of GITHUB_TOKEN=xxxx
. ~/.config/github/env

get_username() { (
    curl -fsSL \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        https://api.github.com/user | jq -r .login
); }

get_username
