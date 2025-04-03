#!/bin/bash

ORG="$1"
EXCEL_FILE="$2"
SHEET_NAME="$3"

AZURE_GROUP_COLUMN="$4"
GITHUB_TEAM_COLUMN="$5"

# [Optional] The new column/field name this script will add
GITHUB_GROUP_ID_COLUMN="${6:-GITHUB_GROUP_ID}"

if [ -z "$ORG" ] || [ -z "$EXCEL_FILE" ] || [ -z "$SHEET_NAME" ] || [ -z "$AZURE_GROUP_COLUMN" ] || [ -z "$GITHUB_TEAM_COLUMN" ]; then
  echo "Usage: $0 <org> <excel_file> <sheet_name> <azure_group_column> <github_team_column> [github_group_id_column]"
  exit 1
fi

CSV_FILE="${EXCEL_FILE%.xlsx}.csv"
CSV_AS_JSON_FILE="${EXCEL_FILE%.xlsx}.json"

GH_EXTERNAL_GROUPS_FILE="${ORG}_external_groups.json"

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

fetch_external_groups() {
  local org_name="$1"
  local response
  response=$(gh api --paginate --slurp \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/orgs/${org_name}/external-groups")
  echo "$response" | jq '[.[] | .groups[]]'
}

__install_dependencies || exit 1

# TODO verify the org exists using the current user's token
# VERIFY_ORG=$(gh api "/orgs/${ORG}" 2>&1)

echo "Export ${SHEET_NAME} sheet from ${EXCEL_FILE} file to ${CSV_FILE}..."
excel_sheet_to_csv "${EXCEL_FILE}" "${SHEET_NAME}" > "${CSV_FILE}"
echo "Converting exported sheet as CSV from ${CSV_FILE} to JSON here: ${CSV_AS_JSON_FILE}..."
csv_to_json "${CSV_FILE}" > "${CSV_AS_JSON_FILE}"

echo "Fetch existing external groups from ${ORG}..."
GH_GROUPS=$(fetch_external_groups "$ORG")
GH_GROUPS_LENGTH=$(echo "$GH_GROUPS" | jq length)
echo "Fetched ${GH_GROUPS_LENGTH} external groups from ${ORG}, saving to ${GH_EXTERNAL_GROUPS_FILE}..."
echo "$GH_GROUPS" > "${ORG}_external_groups.json"

echo "Mapping Azure groups to GitHub groups..."
output_array="[]"
echo "$GH_GROUPS" | jq -c '.[]' | while IFS= read -r group; do
  echo "$group"
  group_name=$(echo "$group" | jq -r '.group_name')
  group_id=$(echo "$group" | jq -r '.group_id')

  # Find matching rows in the CSV file for the current GitHub group
  matching_row=$(jq -r --arg group_name "$group_name" --arg azure_column "$AZURE_GROUP_COLUMN" \
    '.[] | select(.[$azure_column] == $group_name)' "$CSV_AS_JSON_FILE")

  if [ -n "$matching_row" ]; then
    github_team_name="$(echo "$matching_row" | jq --arg github_team_column "$GITHUB_TEAM_COLUMN" '.[$github_team_column]')"
    # echo "GitHub team name: ${github_team_name}"
    # echo "Found matching rows for GitHub group: ${group_name}"
    # echo "$matching_row"

    json_array=$(echo "$json_array" | jq --arg group_id "$group_id" --arg group_name "$group_name" --arg github_team_name "$github_team_name" \
      '. += [{ "group_id": $group_id, "group_name": $group_name, "github_team_name": $github_team_name }]')
  else
    echo "No matching rows found for GitHub group: ${group_name}"
  fi
done

echo "Saving the mapping to ${ORG}_group_mapping.json..."
echo "$json_array" > "${ORG}_group_mapping.json"

# echo "Linking groups from that JSON to ${ORG}..."
# jq -c '.[]' "$CSV_AS_JSON_FILE" | while read -r group; do
#   group_name=$(echo "$group" | jq -r '.GitHub\ Team')
#   # echo "$group_name"

#   group_id=$(echo "$GH_GROUPS" | jq -r ".[] | select(.name == \"${group_name}\") | .id")
#   # echo "$group_id"

#   echo "Linking group: ${group_name} (${group_id}) to ${ORG}"
#   # TODO use (create-team                   Creates a GitHub team and optionally links it to an IdP group.)

#   # gh api \
#   #   -H "Accept: application/vnd.github+json" \
#   #   -H "X-GitHub-Api-Version: 2022-11-28" \
#   #   -X PUT \
#   #   "/orgs/${ORG}/external-groups/${group_id}" \
#   #   -f group_id="${group_id}" \
#   #   -f group_name="${group_name}"
# done

# sh ./link-gh-groups.sh 'avolta-ag' 'Github Azure mappings.xlsx' 'GitHub - Azure Mapping' 'Azure Group Actual' 'GitHub Team'
# sh ./link-gh-groups.sh Solidify-EMU-Test 'Github Azure mappings.xlsx' 'GitHub - Azure Mapping' 'Azure Group Actual' 'GitHub Team'
# jq -r --arg group_name "AZG_GitHub_SSO_GH_CA_Advertisement-Promotion_AutoQA" --arg azure_column "Azure Group Actual" '.[] | select(.[$azure_column] == $group_name)' ./Github\ Azure\ mappings.json
