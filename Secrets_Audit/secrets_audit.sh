build_repo_secrets_list() {
  repo_name=$1
  secret_type=$2

  REPO_SECRETS=$(gh secret list --app $secret_type --repo $repo_name)

  echo "$REPO_SECRETS"
}

build_org_secrets_list() {
  org_name=$1
  secret_type=$2

  REPO_SECRETS=$(gh secret list --app $secret_type --org $org_name)

  echo "$REPO_SECRETS"
}

RESULT_SECRETS=$'\n\n# Secrets \n'

declare -A secrettypes0=(
    [name]='Actions Secrets'
    [type]='actions'
    [repo_results]=''
    [org_results]=''
)
declare -A secrettypes1=(
    [name]='Dependabot Secrets'
    [type]='dependabot'
    [repo_results]=''
    [org_results]=''
)
declare -A secrettypes2=(
    [name]='Codespaces Secrets'
    [type]='codespaces'
    [repo_results]=''
    [org_results]=''
)

declare -n secrettypes

REPOS=$(gh repo list $ORG_NAME --json name --jq '.[].name')

for secrettypes in ${!secrettypes@}; do
    echo "${secrettypes[type]}"

    RESULT_SECRETS+=$'\n\n## '
    RESULT_SECRETS+="${secrettypes[name]}"
    RESULT_SECRETS+=$'\n\n'

    while read -r repo ; do
        echo "Auditing repository $repo ..."

        REPO_SECRETS=$(build_repo_secrets_list $ORG_NAME/$repo "${secrettypes[type]}")

        if [ "$REPO_SECRETS" != "" ]; then
            secrettypes[repo_results]+=$'\n\n### Repository: '
            secrettypes[repo_results]+="$repo"
            secrettypes[repo_results]+=$'\n\n```\n'
            secrettypes[repo_results]+=$REPO_SECRETS
            secrettypes[repo_results]+=$'\n```\n\n'
        fi
    done <<< $REPOS

    ORG_SECRETS=$(build_org_secrets_list $ORG_NAME "${secrettypes[type]}")
    if [ "$ORG_SECRETS" != "" ]; then
        secrettypes[org_results]+=$'\n\n### Org: '
        secrettypes[org_results]+="$ORG_NAME"
        secrettypes[org_results]+=$'\n\n```\n'
        secrettypes[org_results]+=$ORG_SECRETS
        secrettypes[org_results]+=$'\n```\n\n'
    fi

    RESULT_SECRETS+=${secrettypes[org_results]}
    RESULT_SECRETS+=${secrettypes[repo_results]}
done
unset -n secrettypes

gh issue comment $ISSUE_URL --body "$RESULT_SECRETS"