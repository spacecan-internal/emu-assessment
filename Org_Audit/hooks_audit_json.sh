#!/bin/bash


HOOKS=$(gh api "/orgs/$ORG_NAME/hooks" | jq -r ".[] | {id, name, active, type}" )

RESULT_HOOKS=''
RESULT_HOOKS+=$HOOKS

echo "$RESULT_HOOKS" > orghooks.json