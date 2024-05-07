#!/bin/bash

# Read the JSON file and group the repositories by login
jq -r 'reduce .[] as $item ({}; .[$item.users[].login] += [$item.repo]) | to_entries[] | "# " + .key, (.value[] | "* " + .)' users.json >> users.md