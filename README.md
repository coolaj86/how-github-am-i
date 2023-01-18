# How GitHub am I?

Shows (nearly) all Repos that you have historically contributed to via the GitHub v3 and v4 APIs

How? By paginating through the GitHub v3 (RESTful) and v4 (GraphQL) APIs to see for which Repos you have closed PRs or "recent" contributions.

## Install

1. Install [`jq`](https://webinstall.dev/jq) (JSON-Query)
    ```sh
    # Mac, Linux
    curl -sS https://webi.sh/jq | sh
    source ~/.config/envman/PATH.env
    ```
    ```sh
    # Windows 10+
    curl.exe https://webi.ms/jq | pwsh
    ```
2. Go to from https://github.com/settings/tokens
3. Create a new _Personal Access Token_
4. Put it into this ENV file \
   in the form of `GITHUB_TOKEN=ghp_xxxx`
    ```sh
    ~/.config/github/env
    ```
5. Install `how-github-am-i`

    ```sh
    mkdir -p ~/.local/opt/ ~/.local/bin/ ~/.config/github
    chmod 0700 ~/.config/github

    git clone git@github.com:coolaj86/how-github-am-i.git ~/.local/opt/how-github-am-i

    ln -s ~/.local/opt/how-github-am-i/how-github-am-i.sh ~/.local/bin/how-github-am-i
    ```

## Usage

```sh
pushd ~/.local/opt/how-github-am-i/
./how-github-am-i.sh
```

Or just

```sh
how-github-am-i
```

Example output:

```text
caddyserver/caddy:
http://www.github.com/caddyserver/caddy/commits?author=coolaj86
watchexec/watchexec:
http://www.github.com/watchexec/watchexec/commits?author=coolaj86
webinstall/webi-installers:
http://www.github.com/webinstall/webi-installers/commits?author=coolaj86
```

## How it Works

GitHub API v4 allows you to see which repos you've contributed to, but only recently:

```sh
# get the GraphQL Query without spaces
my_query="$(echo $(echo '
    query {
      viewer {
        repositoriesContributedTo(
            first: 100,
            '"${my_after:-}"'
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
'))"

curl -fsSL -X POST https://api.github.com/graphql \
    -H 'Content-Type: application/json' \
    -H "Authorization: bearer ${GITHUB_TOKEN}" \
    -d '{"query": "'"${my_query}"'"}'
```

GitHub API v3 will let you see ALL repos in which you have closed pull requests
(but that does not account for direct commits):

```sh
# exports GITHUB_TOKEN into the current environment
. ~/.config/github/env
```

```sh
# get the login name by the token
my_user="$(
    curl -fsSL https://api.github.com/user \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        -H "X-GitHub-Api-Version: 2022-11-28" |
        jq -r .login
)"
```

```sh
curl -sSL --get "https://api.github.com/search/issues" \
    -H "Authorization: bearer ${GITHUB_TOKEN}" \
    --data-urlencode "q=type:pr state:closed author:${my_user}" \
    --data-urlencode "per_page=100" \
    --data-urlencode "page=${my_page}"
```

Example:

<https://api.github.com/search/issues?q=type:pr+state:closed+author:coolaj86&per_page=100&page=1>

## Caveats

This will both have false positives (closed PRs that were not accepted) and false negatives (possibly missing repos you've committed to without a PR, but not recently).

Sorry, it's the best we can do with what we have available today.

## License

MPL-2.0

Copyright 2023 AJ ONeal

This Source Code Form is subject to the terms of the Mozilla Public \
License, v. 2.0. If a copy of the MPL was not distributed with this \
file, You can obtain one at <https://mozilla.org/MPL/2.0/>.
