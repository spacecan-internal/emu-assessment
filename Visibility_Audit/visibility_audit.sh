REPOS=$(gh api /orgs/$ORG_NAME/repos | jq -r '.[] | select(.visibility != "private") | "| \(.name) | \(.visibility) |" ')

RESULT_VISIBILITY=$'\n\n# Non private repositories \n'

RESULT_VISIBILITY+=$'| Repository | Visibility |'
RESULT_VISIBILITY+=$'\n'
RESULT_VISIBILITY+=$'|---|---|'
RESULT_VISIBILITY+=$'\n'
RESULT_VISIBILITY+=$"$REPOS"
RESULT_VISIBILITY+=$'\n\n'
RESULT_VISIBILITY+=$'\n'

gh issue comment $ISSUE_URL --body "$RESULT_VISIBILITY"

