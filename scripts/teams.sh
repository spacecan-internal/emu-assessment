#!/bin/bash

# Read the JSON file and group the repositories by team name
jq -r 'reduce .[] as $item ({}; .[$item.teams[].name] += [$item.repo]) | to_entries[] | "# " + .key, (.value[] | "* " + .)' teams.json >> teams.md
