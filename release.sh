#!/bin/bash

# Replace these with your tags and repo
TAG1="v1.0"
TAG2="v2.0"
REPO="OWNER/REPO"

# Fetch all merge commits between tags and get associated PR details
for sha in $(git log "$TAG1..$TAG2" --merges --pretty=format:"%H"); do
  echo "Processing commit: $sha"
  # Use gh to fetch PR details from the commit hash
  PR_DETAILS=$(gh pr list --state merged --search "$sha" --repo "$REPO" --json number,title,body,mergedAt)

  # Check if PR details are found
  if [ -n "$PR_DETAILS" ] && [ "$PR_DETAILS" != "[]" ]; then
    echo "$PR_DETAILS" | jq -r '.[] | "PR #\(.number): \(.title)\nDescription: \(.body)\nMerged on: \(.mergedAt)\n"'
  else
    echo "No PR found for commit: $sha"
  fi
done
