#!/bin/bash
REPOS=$(jq -r ".[].name" repos.json)

echo "[]" > repo_teams.json

while read -r repo ; do
    echo "Auditing repository $repo ..."

    ENV=$(gh api /repos/$ORG_NAME/$repo/teams | REPO=$repo jq '[ { repo: env.REPO, teams: [ .[] | { id: .id, name: .name }] } ] } ]')
    echo "$ENV" > repo_team.json

    cp teams.json tmp.json
    jq -sc add tmp.json repo_team.json > teams.json

    rm -rf repo_team.json
    rm -rf tmp.json

done <<< "$REPOS"