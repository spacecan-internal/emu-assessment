#!/bin/bash

# This script fetches repositories Name & isArchived a specified GitHub organization,
# along with its custom properties, and saves the data to a CSV file.

ORG="$1"
LIMIT=${2:-1000}

if [ -z "$ORG" ]; then
  echo "Usage: $0 <ORG>"
  exit 1
fi

FILE="${ORG}_repos_properties.csv"

echo "Fetching repository properties for organization: $ORG with a limit of $LIMIT repositories. Output will be saved to $FILE..."

echo "repo,is_archived" > "$FILE"

gh repo list "$ORG" --json name,isArchived --limit "$LIMIT" | jq -rc 'sort_by(.name | ascii_downcase) | .[] | [.name, .isArchived] | @csv' > "$FILE"
