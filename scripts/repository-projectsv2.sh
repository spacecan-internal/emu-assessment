#!/bin/bash

printf "# Repository Projects V2\n" > repository-projectsv2.md

# Read the JSON file and format the data into markdown
markdown_data=$(jq -r '.[] | "## " + .nameWithOwner + "\n", (.projectsV2.nodes[] | "### Project: " + .title + "\n")' repository-projectsv2.json)

# Write the markdown data into a file
echo "${markdown_data}" > repository-projectsv2.md
