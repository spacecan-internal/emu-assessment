#!/bin/bash

# This script automates the process of linking GitHub teams to Azure groups using data from an Excel file.
#
# It performs the following steps:
# 1. Installs required dependencies (Homebrew, GitHub CLI, pipx, xlsx2csv).
# 2. Exports a specific sheet from the provided Excel file to a CSV file.
# 3. Converts the CSV file to a JSON file for easier processing.
# 4. Iterates over the JSON data to extract Azure group and GitHub team information.
# 5. Uses the GitHub CLI to create and link GitHub teams to Azure groups based on the extracted data.
# 6. Verifies the user's access to the specified GitHub organization.
# 7. Ensures the required GitHub Personal Access Token (GH_PAT) is set for authentication.

# Usage:
# ./link-gh-teams-by-id.sh <org> <excel_file> <sheet_name> <azure_group_column> <github_team_column>
# Example:
# ./link-gh-teams-by-id.sh 'my-org' 'Github Azure mappings.xlsx' 'GitHub - Azure Mapping' 'Azure Group Actual' 'GitHub Team'


ORG="$1"
EXCEL_FILE="$2"
SHEET_NAME="$3"

AZURE_GROUP_COLUMN="$4"
GITHUB_TEAM_COLUMN="$5"

if [ -z "$ORG" ] || [ -z "$EXCEL_FILE" ] || [ -z "$SHEET_NAME" ] || [ -z "$AZURE_GROUP_COLUMN" ] || [ -z "$GITHUB_TEAM_COLUMN" ]; then
  echo "Usage: $0 <org> <excel_file> <sheet_name> <azure_group_column> <github_team_column>"
  exit 1
fi

CSV_FILE="${EXCEL_FILE%.xlsx}.csv"
CSV_AS_JSON_FILE="${EXCEL_FILE%.xlsx}.json"

# GH_EXTERNAL_GROUPS_FILE="${ORG}_external_groups.json"
# GH_GROUPS_MAPPING_FILE="${ORG}_group_mapping.json"

__install_dependencies() {
  command -v brew >/dev/null 2>&1 || {
    echo "brew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || { echo "Failed to install brew"; exit 1; }
  }

  command -v gh >/dev/null 2>&1 || {
    echo "gh not found. Installing..."
    brew install gh || { echo "Failed to install gh"; exit 1; }
  }

  command -v pipx >/dev/null 2>&1 || {
    echo "pipx not found. Installing..."
    brew install pipx || { echo "Failed to install pipx"; exit 1; }
    pipx ensurepath
  }

  command -v xlsx2csv >/dev/null 2>&1 || {
    echo "xlsx2csv not found. Installing..."
    pipx install xlsx2csv || { echo "Failed to install xlsx2csv"; exit 1; }
  }
}

excel_sheet_to_csv() {
  local excel="$1"
  local sheet="$2"
  xlsx2csv -n "$sheet" "$excel" | tail -n +2
}

csv_to_json() {
  python3 -c 'import csv, json, sys; print(json.dumps([dict(r) for r in csv.DictReader(sys.stdin)]))' < "$1"
}

get_by_key_from_json_object() {
  local json_object="$1"
  local key="$2"
  echo "$json_object" | jq --arg key "$key" '.[$key]' -r
}

create_team_using_gh_gei() {
  local org="$1"
  local gh_team="$2"
  local az_group="$3"
  echo "Updating ${org} team: ${gh_team} to IdP group: ${az_group}..."
  gh gei create-team --github-org "$org" --team-name "$gh_team" --idp-group "$az_group"
}

# fetch_all_gh_external_groups() {
#   local org_name="$1"
#   local response
#   response=$(gh api --paginate --slurp \
#   -H "Accept: application/vnd.github+json" \
#   -H "X-GitHub-Api-Version: 2022-11-28" \
#   "/orgs/${org_name}/external-groups")
#   echo "$response" | jq '[.[] | .groups[]]'
# }

__install_dependencies || exit 1

VERIFY_ORG=$(gh api "/user/memberships/orgs/${ORG}" 2>/dev/null | jq -r '.state')
if [ "$VERIFY_ORG" != "active" ]; then
  echo "Your GitHub account does not have access to the organization '${ORG}' or you are not logged in."
  echo "Please ensure you are logged in with 'gh auth login' and have the necessary permissions."
  echo "Or maybe you need to 'gh auth switch' to the correct account."
  exit 1
fi

echo "Export ${SHEET_NAME} sheet from ${EXCEL_FILE} file to ${CSV_FILE}..."
excel_sheet_to_csv "${EXCEL_FILE}" "${SHEET_NAME}" > "${CSV_FILE}"

echo "Converting exported sheet as CSV from ${CSV_FILE} to JSON here: ${CSV_AS_JSON_FILE}..."
csv_to_json "${CSV_FILE}" > "${CSV_AS_JSON_FILE}"

if [ -z "$GH_PAT" ]; then
  echo "GH_PAT is not set. Please set the GH_PAT environment variable."
  echo "Please follow the instructions here: https://docs.github.com/en/migrations/using-github-enterprise-importer/migrating-between-github-products/managing-access-for-a-migration-between-github-products#granting-the-migrator-role-with-the-gei-extension"
  echo "You'll need these requird scoped in your ==>(CLASSIC)<== PAT: https://docs.github.com/en/migrations/using-github-enterprise-importer/migrating-between-github-products/managing-access-for-a-migration-between-github-products#granting-the-migrator-role-with-the-gei-extension"
  exit 1
fi

while IFS= read -r group; do
  az_group="$(get_by_key_from_json_object "$group" "$AZURE_GROUP_COLUMN")"
  gh_team="$(get_by_key_from_json_object "$group" "$GITHUB_TEAM_COLUMN")"

  create_team_using_gh_gei "$ORG" "$gh_team" "$az_group"
done < <(jq -c '.[]' "$CSV_AS_JSON_FILE")

# GH_GROUPS=$(fetch_all_gh_external_groups "$ORG")
# GH_GROUPS_LENGTH=$(echo "$GH_GROUPS" | jq length)
# echo "Fetched ${GH_GROUPS_LENGTH} external groups from ${ORG}, saving to ${GH_EXTERNAL_GROUPS_FILE}..."
# echo "$GH_GROUPS" > "$GH_EXTERNAL_GROUPS_FILE"

# json_array="[]"
# while IFS= read -r group; do
#   group_id="$(echo "$group" | jq -r '.group_id')"
#   group_name="$(echo "$group" | jq -r '.group_name')"

#   # Find matching rows in the exported csv_to_json file for the current GitHub group
#   matching_row=$(jq -r --arg group_name "$group_name" --arg azure_column "$AZURE_GROUP_COLUMN" \
#     '.[] | select(.[$azure_column] == $group_name)' "$CSV_AS_JSON_FILE")

#   if [ -n "$matching_row" ]; then
#     gh_team="$(get_by_key_from_json_object "$matching_row" "$GITHUB_TEAM_COLUMN")"

#     # echo "AZ_Group: ${group_name} - GH_ID: ${group_id} - GH_Team: ${gh_team}"

#     json_array=$(echo "$json_array" | jq -c --arg group_id "$group_id" --arg group_name "$group_name" --arg gh_team "$gh_team" \
#       '. += [{ "group_id": $group_id, "group_name": $group_name, "gh_team": $gh_team }]')
#   else
#     echo "No matching rows found for GitHub group: ${group_name}"
#   fi
# done < <(jq -c '.[]' "$GH_EXTERNAL_GROUPS_FILE")

# echo "Saving mapped records json file to to ${GH_GROUPS_MAPPING_FILE}..."
# echo "$json_array" > "$GH_GROUPS_MAPPING_FILE"

# echo "Linking ${ORG} teams..."
# jq -c '.[]' "$GH_GROUPS_MAPPING_FILE" | while read -r group; do
#   group_id=$(echo "$group" | jq -r '.group_id')
#   group_name=$(echo "$group" | jq -r '.group_name')
#   gh_team=$(echo "$group" | jq -r '.gh_team')

#   echo "Linking: ${group_name} - [${gh_team}] to (${group_id})"
#   create_team_using_gh_gei "$ORG" "$gh_team" "$group_name"
# done

# jq -r --arg group_name "AZG_GitHub_SSO_GH_CA_Advertisement-Promotion_AutoQA" --arg azure_column "Azure Group Actual" '.[] | select(.[$azure_column] == $group_name)' ./Github\ Azure\ mappings.json
