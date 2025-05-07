#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/lib.sh"

# This script fetches repositories Name & isArchived from a specified GitHub organization,
# and saves the data to a CSV file.

if [ -z "$1" ]; then
  echo "Usage: $0 <ORG> [LIMIT:1000] [OUTPUT_FILE:<ORG>_repos_<timestamp>.csv]"
  exit 1
fi

ORG="$1"
LIMIT=${2:-1000}
FILE="${3:-${ORG}_repos_$(get_timestamp).csv}"

echo "Fetching repository properties for organization: $ORG with a limit of $LIMIT repositories. Output will be saved to $FILE"

# Check if the user has access to the organization
check_gh_auth_org_membership "$ORG"

# Use gh_repos_list function from lib.sh to fetch repositories
repos=$(gh_repos_list "$ORG" "true" "$LIMIT")
if [ $? -ne 0 ]; then
  print_error "Failed to fetch repositories for organization $ORG"
  exit 1
fi

# Create CSV header
echo "repo,is_archived" > "$FILE"

# Process repositories and write to CSV file
if ! echo "$repos" | jq -rc '.[] | [.name, .isArchived] | @csv' >> "$FILE"; then
  print_error "Error: Failed to process repository data with jq"
  exit 1
fi

print_success "Repository data exported to $FILE"
