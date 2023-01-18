#!/bin/sh
set -e
set -u

# shellcheck disable=SC1090
# 1. Go to from https://github.com/settings/tokens
# 2. Put token into this ENV file
#    in the form of GITHUB_TOKEN=xxxx
. ~/.config/github/env

fn_build_query_next_page() { (
    my_end_cursor="${1:-}"
    my_after=""
    if [ -n "${my_end_cursor}" ]; then
        my_after="after: \\\"${my_end_cursor}\\\","
    fi
    # we want to one-line this (word splitting, useless echo)
    # shellcheck disable=SC2046,SC2116
    echo $(
        echo '
            query {
              viewer {
                repositoriesContributedTo(
                    first: 100,
                    '"${my_after}"'
                    contributionTypes: [
                        COMMIT,
                        PULL_REQUEST,
                        REPOSITORY
                    ]
                ) {
                  pageInfo {
                    startCursor
                    hasNextPage
                    endCursor
                  }
                  nodes {
                    nameWithOwner
                  }
                }
              }
            }
        '
    )
); }

fn_get_all_contribs() { (
    my_end_cursor="${1:-}"

    # we want word-splitting to one-line this
    # shellcheck disable=SC2086,SC2116
    my_query="$(fn_build_query_next_page "${my_end_cursor}")"

    echo "GitHub v4: Getting page from cursor '${my_end_cursor}'..." > /dev/tty
    my_response="$(
        curl -fsSL -X POST https://api.github.com/graphql \
            -H 'Content-Type: application/json' \
            -H "Authorization: bearer ${GITHUB_TOKEN}" \
            -d '{"query": "'"${my_query}"'"}'
    )"

    my_has_next="$(echo "${my_response}" | jq -r .data.viewer.repositoriesContributedTo.pageInfo.hasNextPage)"
    #echo "${my_has_next}"

    my_end_cursor="$(echo "${my_response}" | jq -r .data.viewer.repositoriesContributedTo.pageInfo.endCursor)"
    #echo "${my_end_cursor}"

    my_contribs="$(echo "${my_response}" | jq -r .data.viewer.repositoriesContributedTo.nodes[].nameWithOwner)"
    echo "${my_contribs}"

    if ! [ "true" = "${my_has_next}" ]; then
        return 0
    fi

    fn_get_all_contribs "${my_end_cursor}"
); }

fn_get_all_contribs | sort -u
