PROJECTS_V2_RESULT=$(gh api graphql -f query='
  query{
    organization(login: "'$ORG_NAME'"){
      projectsV2(first: 100) { 
        nodes {
          id
          title
        }
      }
    }
  }' | jq '{ projectsV2: [ .data.organization.projectsV2.nodes[] ] }'
)

PROJECTS_OLD_RESULT=$(gh api graphql -f query='
  query{
    organization(login: "'$ORG_NAME'"){
      projects(first: 100) { 
        nodes {
          id
          name
        }
      }
    }
  }' | jq '{ projectsOld: [ .data.organization.projects.nodes[] ] }'
)

echo $PROJECTS_OLD_RESULT > PROJECTS_OLD_RESULT.json
echo $PROJECTS_V2_RESULT > PROJECTS_V2_RESULT.json

JSON_RESULT=$(jq -s 'add' PROJECTS_OLD_RESULT.json PROJECTS_V2_RESULT.json | ORG_NAME="$ORG_NAME" jq '[{ org: env.ORG_NAME, projects: .}]')

echo $JSON_RESULT > projects.json