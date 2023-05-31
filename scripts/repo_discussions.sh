#!/bin/bash

set -eo pipefail

REPOS=$(jq -r ".[].name" repos.json)
echo "[]" > discussions.json

while read -r repo ; do
    echo "Auditing repository $repo ..."
    DISCUSSIONS_RESULT=$(gh api graphql --paginate -H X-Github-Next-Global-ID:true -f query='
      query getRepoDiscussions($endCursor: String = null){
        repository(owner: "'$ORG_NAME'", name: "'$repo'"){
           discussions(first: 100, after: $endCursor) {
            totalCount
            nodes {
                id
            }
            pageInfo {
                hasNextPage
                endCursor
          }

          }
        }
      }' | REPO=$repo jq '[{ repo: env.REPO, discussions: .data.repository.discussions.totalCount }]'
    )
    echo "$DISCUSSIONS_RESULT" > repo_discussions.json

    cp discussions.json tmp.json
    jq -sc add tmp.json repo_discussions.json > discussions.json

    rm -rf repo_discussions.json
    rm -rf tmp.json

done <<< "$REPOS"