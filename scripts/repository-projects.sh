#!/bin/bash

printf "# Repository Projects\n" > repository-projects.md

# Read the JSON file and format the data into markdown
markdown_data=$(jq -r '.[] | "## " + .nameWithOwner + "\n", (.projects.nodes[] | "### Project: " + .name + "\n")' repository-projects.json)

# Write the markdown data into a file
echo "${markdown_data}" > repository-projects.md
