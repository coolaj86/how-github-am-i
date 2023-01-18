#!/bin/sh
set -e
set -u

my_path="$(
    dirname "${0}"
)"

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

show_all() { (
    sh "${my_path}"/get-recent-contribs-v4.sh
    sh "${my_path}"/get-all-prs-v3.sh "${my_user}"
); }

main() { (
    my_user="$(get_username)"
    my_repos="$(
        show_all | sort -u
    )"

    # works because there are no spaces in repo names
    for my_repo in ${my_repos}; do
        printf "%s:\n" "${my_repo}"
        printf "http://www.github.com/%s/commits?author=%s\n" "${my_repo}" "${my_user}"
    done
); }

main
