#!/bin/bash

# Check if two tags are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <start_tag> <end_tag>"
    exit 1
fi

start_tag="$1"
end_tag="$2"

# Get all merge commits between the tags
merged_prs=$(git log -- "$start_tag".."$end_tag" --merges --pretty=format:'%s' | grep -E "Merge pull request #" | sed -E 's/Merge pull request #([0-9]+) from.*/\1/')

# Check if any PRs were found
if [ -z "$merged_prs" ]; then
    echo "No merged pull requests found between $start_tag and $end_tag"
    exit 0
fi

# Iterate through each PR number
for pr in $merged_prs; do
    # Try to get PR title using GitHub CLI
    title=$(gh pr view "$pr" --json title --jq .title 2>/dev/null)
    
    # If GitHub CLI fails, use a basic fallback
    if [ -z "$title" ]; then
        title="PR #$pr (Title unavailable)"
    fi
    
    echo "PR #$pr: $title"
done
