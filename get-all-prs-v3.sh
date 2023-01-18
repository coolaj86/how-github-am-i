#!/bin/sh
set -e
set -u

if [ -z "${1:-}" ]; then
    echo "Usage: get-all-prs-v3.sh <github-username>"
    exit 1
fi
my_user="${1}"

# shellcheck disable=SC1090
# 1. Go to from https://github.com/settings/tokens
# 2. Put token into this ENV file
#    in the form of GITHUB_TOKEN=xxxx
. ~/.config/github/env

my_page=1

fn_get_next() { (
    # Note page=0 and page=1 are the same
    my_page="${1:-1}"
    my_count="${2:-}"
    echo "GitHub v3: Fetching page '${my_page}' of PRs ('${my_count:-unknown}' remaining)" >> /dev/tty

    # Ex: https://api.github.com/search/issues?q=type:pr+state:closed+author:coolaj86&per_page=100&page=1
    my_response="$(
        curl -sSL --get "https://api.github.com/search/issues" \
            -H "Authorization: bearer ${GITHUB_TOKEN}" \
            --data-urlencode "q=type:pr state:closed author:${my_user}" \
            --data-urlencode "per_page=100" \
            --data-urlencode "page=${my_page}"
    )"
    if [ -z "${my_response}" ]; then
        echo >&2 ''
        echo >&2 'Error: Your commits are too powerful!'
        echo >&2 "       WHaaa!? Your power level... it's over 9000!"
        echo >&2 ''
        echo >&2 '(you have more than 10 pages of closed PRs - 1000+ pRs)'
        echo >&2 ''
    fi
    #printf "%s\n" "${my_response}"

    if [ -z "${my_count}" ]; then
        my_count="$(
            printf "%s\n" "${my_response}" | jq .total_count
        )"
    fi
    #echo "debug: my_count: ${my_count}" >> /dev/tty

    if [ "${my_count}" -lt 100 ]; then
        return
    fi

    printf "%s\n" "${my_response}" | jq -r '.items[].repository_url' | sed 's:https\://api.github.com/repos/::g'

    my_count=$((my_count - 100))
    my_page=$((my_page + 1))
    fn_get_next "${my_page}" "${my_count}"
); }

fn_get_next 1 | sort -u
