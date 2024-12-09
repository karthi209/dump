#!/bin/bash

# Check if two tags are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <start_tag> <end_tag>"
    exit 1
fi

start_tag="$1"
end_tag="$2"

# Get all merge commits between the tags
merged_prs=$(git log "$start_tag".."$end_tag" --merges --pretty=format:'%s' | grep -E "Merge pull request #" | sed -E 's/Merge pull request #([0-9]+) from.*/\1/')

# Iterate through each PR number and get its title
for pr in $merged_prs; do
    # Try to get PR title using GitHub CLI
    title=$(gh pr view "$pr" --json title --jq .title 2>/dev/null)
    
    # If GitHub CLI fails, use a fallback
    if [ -z "$title" ]; then
        title="PR #$pr (Title unavailable)"
    fi
    
    echo "PR #$pr: $title"
done
