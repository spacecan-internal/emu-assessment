add_value() {
  value=$1

  if [ "$value" = "null" ] || [ "$value" = "0" ] || [ "$value" = "[]" ];
  then
    SUMMARY+=$"   |"
  else
    SUMMARY+=$" x |"
  fi
}

SUMMARY=$'## Organization \n\n'
SUMMARY+=$'| Org | Apps | Actions Secrets | Dependabot Secrets | Codespaces Secrets | Projects | Packages | '
SUMMARY+=$' \n|---|---|---|---|---|---|---|  \n '

org_name=$(jq -r '.[0] | .org' org.json)
org_apps=$(jq -r '.[0] | .apps' org.json)
org_actions_secrets=$(jq -r '.[0] | .actions_secret' org.json)
org_dependabot_secret=$(jq -r '.[0] | .dependabot_secret' org.json)
org_codespaces_secret=$(jq -r '.[0] | .codespaces_secret' org.json)
org_projects=$(jq -r '.[0] | .projects' org.json)
org_packages=$(jq -r '.[0] | .packages' org.json)

SUMMARY+=$'| '
SUMMARY+="$org_name"
SUMMARY+=$' |'

add_value $org_apps
add_value $org_actions_secrets
add_value $org_dependabot_secret
add_value $org_codespaces_secret
add_value $org_codespaces_secret
add_value $org_projects
add_value $org_packages

SUMMARY+=$'\n\n\n## Repositories \n\n'

SUMMARY+=$'\n\n\n | Repo | Visibility | LFS | Permissions | Actions Secrets | Dependabot Secrets | Codespaces Secrets | Environments | Branch protection rules | Discussions | '
SUMMARY+=$' \n|---|---|---|---|---|---|---|---|---|---|  \n '

while read repo; do
  repo_name=$(jq -r '. | .repo' <<< $repo)
  visibility=$(jq -r '. | .visibility' <<< $repo)
  lfs=$(jq -r '. | .lfs' <<< $repo)
  permissions=$(jq -c '. | .permissions' <<< $repo)
  actions_secrets=$(jq -c '. | .actions_secret' <<< $repo)
  dependabot_secret=$(jq -c '. | .dependabot_secret' <<< $repo)
  codespaces_secret=$(jq -c '. | .codespaces_secret' <<< $repo)
  env=$(jq -c '. | .env' <<< $repo)
  branchProtectionRules=$(jq -c '. | .branchProtectionRules' <<< $repo)
  discussions=$(jq -c '. | .discussions' <<< $repo)

  SUMMARY+=$'| '
  SUMMARY+="$repo_name"
  SUMMARY+=$' |'

  add_value "$visibility"
  add_value "$lfs"
  add_value "$permissions"
  add_value "$actions_secrets"
  add_value "$dependabot_secret"
  add_value "$codespaces_secret"
  add_value "$env"
  add_value "$branchProtectionRules"
  add_value "$discussions";
  SUMMARY+=$' \n '

done <<< $(jq -c '.[]' repositories.json)

echo "$SUMMARY" > summary.md 