#!/bin/bash

set -eo pipefail
mkdir -p ../../reports
REPOS=$(jq -r ".[].name" "${2}")

#--------------------------------------------------
# Classic projects
#--------------------------------------------------
DEST="../../reports/repository-projects.json"
echo "[]" >$DEST
# iterate over REPOS
while read -r repo; do
  echo "Getting repo: $repo"

  REPOSITORIES=$(gh api graphql \
    -H X-Github-Next-Global-ID:true \
    -F owner="${1}" \
    -F name="$repo" \
    -f query='query getClassicProjects($owner: String!, $name: String!, $endCursor: String = null) {
          repository(owner: $owner, name: $name) {
            name
            nameWithOwner
            projects(first: 100, after: $endCursor) {
              nodes {
                id
                name
              }
              pageInfo {
                hasNextPage
                endCursor
              }
             }
        }
        }' \
    --jq '.data.repository' |
    jq -s '.')

  jq 'map(select(.projects.nodes | length > 0))' <<<"$REPOSITORIES" >repo.json
  cp $DEST tmp.json
  jq -sc add tmp.json repo.json >$DEST
  rm -rf repo.json tmp.json
done <<<"$REPOS"

#--------------------------------------------------
# V2 projects
#--------------------------------------------------
DEST2="../../reports/repository-projectsv2.json"
echo "[]" >$DEST2
while read -r repo; do
  echo "Getting repo: $repo"

  REPOSITORIES=$(gh api graphql \
    -H X-Github-Next-Global-ID:true \
    -F owner="${1}" \
    -F name="$repo" \
    -f query='query getV2Projects($owner: String!, $name: String!, $endCursor: String = null) {
          repository(owner: $owner, name: $name) {
            name
            nameWithOwner
            projectsV2(first: 100, after: $endCursor) {
              nodes {
                id
                title
              }
              pageInfo {
                hasNextPage
                endCursor
              }
             }
        }
        }' \
    --jq '.data.repository' |
    jq -s '.')
  # echo $REPOSITORIES > repo.json
  jq 'map(select(.projectsV2.nodes | length > 0))' <<<"$REPOSITORIES" >repo.json
  cp $DEST2 tmp.json
  jq -sc add tmp.json repo.json >$DEST2
  rm -rf repo.json tmp.json
done <<<"$REPOS"
