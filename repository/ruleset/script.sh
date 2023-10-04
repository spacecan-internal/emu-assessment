#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports

REPOS=$(jq -r ".[].name" "${2}")

DEST="../../reports/ruleset.json"
echo "[]" > "${DEST}"

while read -r repo; do
  echo "Auditing repository ${repo} ..."

  RULESET_RESULT=$(gh api graphql -H X-Github-Next-Global-ID:true -F owner="${1}" -F name="${repo}" -f query='query($owner: String!, $name: String!) {
          repository(owner: $owner, name: $name) {
            rulesets {
              totalCount
            }
          }
        }' | REPO="${repo}" jq '[{ repo: env.REPO, rulesets: .data.repository.rulesets.totalCount }]')

  echo "${RULESET_RESULT}" > repo_ruleset.json
  cp "${DEST}" tmp.json
  jq -sc add tmp.json repo_ruleset.json > "${DEST}"
  rm -rf repo_ruleset.json, tmp.json

done <<<"$REPOS"
