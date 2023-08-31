#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports

# Get all v2 projects for the organization
# Note using fist 100 repositories, as we cannot do nested cursors.
# For complete list of repositories and linked projects, see ./repository/projects/script.sh
PROJECTS_V2_RESULT=$(
  gh api graphql --paginate -H X-Github-Next-Global-ID:true -F login="${1}" -f query='
  query getProjectsV2($login: String!, $endCursor: String = null){
    organization(login: $login){
      projectsV2(first: 100, after: $endCursor) {
        nodes {
          id
          title
          
          repositories(first: 100) {
            totalCount
            nodes {
              id
              name
            }
          }
        }
        pageInfo {
				  hasNextPage
				  endCursor
			  }
      }

    }
  }' | jq '{ projectsV2: [ .data.organization.projectsV2.nodes[] ] }'
)

# Get all classic projects for the organization
PROJECTS_OLD_RESULT=$(
  gh api graphql --paginate -H X-Github-Next-Global-ID:true -F login="${1}" -f query='
  query getProjectsOld($login: String!, $endCursor: String = null){
    organization(login: $login){
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
  }' | jq '{ projectsOld: [ .data.organization.projects.nodes[] ] }'
)

echo "$PROJECTS_OLD_RESULT" >PROJECTS_OLD_RESULT.json
echo "$PROJECTS_V2_RESULT" >PROJECTS_V2_RESULT.json
JSON_RESULT=$(jq -sc 'add' PROJECTS_OLD_RESULT.json PROJECTS_V2_RESULT.json | ORG_NAME="${1}" jq -c '[{ org: env.ORG_NAME, projects: .}]')
echo "$JSON_RESULT" >../../reports/projects.json
rm -rf PROJECTS_OLD_RESULT.json PROJECTS_V2_RESULT.json

#-----------------------------------------------------------
# Filter the projects by repo scope
#-----------------------------------------------------------
# Project V2
REPOS=$(jq -r ".[].name" "$2")
FILTERED=$(jq -r '.[].projects.projectsV2[] | {id, title, type: "projectsV2", name: .repositories.nodes[].name}' ../../reports/projects.json |
  jq -s '.' |
  jq -rc --arg repos "${REPOS[@]}" '.[] | select(.name as $repo | $repos | index($repo))' | jq -s '.' |
  jq -r 'group_by(.name) | map({name: .[0].name, type:.[0].type, projects: map({id, type, title})})')
echo $FILTERED >../../reports/repository-projectsv2.json

# Classic project
REPOS=$(jq -r ".[] | select(.hasProjectsEnabled == true) | .name" "${2}")
PRJDEST=repository-projects.json
OWNER=$1
echo "[]" >$PRJDEST

while read -r repo; do
  echo 'Querying projects for repo: ' $repo
  PROJECTS=$(gh api --paginate -H X-Github-Next-Global-ID:true /repos/$OWNER/$repo/projects |
    jq -r --arg repo $repo '.[] | {id, type: "projects", title: .name, repository: $repo}' |
    jq -s '.')

  echo $PROJECTS >tmp-projects.json
  cp $PRJDEST tmp.json
  jq -sc add tmp.json tmp-projects.json >$PRJDEST
  rm -rf tmp-projects.json tmp.json

done <<<"$REPOS"

cat $PRJDEST | jq -r 'group_by(.repository) | map({repository: .[0].repository, projects: map({id, type, title})})' >../../reports/repository-projects.json
