#!/bin/bash

# Replace these with your tags and repo
TAG1="v1.0"
TAG2="v2.0"
REPO="OWNER/REPO"

# Fetch merge commits and extract PR details
for sha in $(git log "$TAG1..$TAG2" --merges --pretty=format:"%H"); do
  gh pr list --state merged --search "$sha" --json number,title,mergedAt --repo "$REPO" | \
  jq -r '.[] | "#\(.number): \(.title) (merged on \(.mergedAt))"'
done
