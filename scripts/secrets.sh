#!/bin/bash

# Read the JSON file and group the secrets by repo, excluding repos without secrets
# jq -r '.[].repos[] | select(.secrets | length > 0) | "# " + .repo, (.secrets[] | "* " + .)' secrets.json >> secrets.md

# Read the JSON file and group the secrets by repo and secret type, excluding repos without secrets
jq -r '.[] | .secret_type as $st | .repos[] | select(.secrets | length > 0) | "# " + $st + " - " + .repo, (.secrets[] | "* " + .)' secrets.json >> secrets.md
