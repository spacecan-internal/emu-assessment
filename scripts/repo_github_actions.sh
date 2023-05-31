#!/bin/bash
set -eo pipefail
# https://github.com/stoe/action-reporting-cli
npx @stoe/action-reporting-cli \
    --owner SolidifyDemo \
    --token $GITHUB_TOKEN \
    --listeners \
    --uses \
    --exclude \
    --unique true \
    --json ./actions.json
