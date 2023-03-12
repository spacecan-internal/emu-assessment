REPOS=$(gh repo list $ORG_NAME --json name --jq '.[].name')

RESULT_PERMISSIONS=$'\n\n# Permissions \n'

while read -r repo ; do

  USER_PERMISSIONS=$(gh api /repos/$ORG_NAME/$repo/collaborators --jq '.[] | "| \(.login) | \(.role_name) | " ')
  
  RESULT_PERMISSIONS+=$'\n\n## '
  RESULT_PERMISSIONS+="$repo"
  RESULT_PERMISSIONS+=$'\n\n'
  RESULT_PERMISSIONS+=$'| Username | RoleName |'
  RESULT_PERMISSIONS+=$'\n'
  RESULT_PERMISSIONS+=$'|---|---|'
  RESULT_PERMISSIONS+=$'\n'
  RESULT_PERMISSIONS+=$"$USER_PERMISSIONS"
  RESULT_PERMISSIONS+=$'\n\n'
  RESULT_PERMISSIONS+=$'\n'

done <<< $REPOS


gh issue comment $ISSUE_URL --body "$RESULT_PERMISSIONS"

