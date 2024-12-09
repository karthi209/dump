#!/bin/bash

# Function to extract PR info from the latest commit
get_pr_info() {
    # Ensure we're in a git repository
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "Error: Not in a Git repository" >&2
        return 1
    }

    # Get the full commit message
    local commit_message=$(git log -1 --pretty=%B)

    # Look for PR tags (common formats)
    local pr_info=""
    local start_patterns=("<pr-info>" "\[PR\]" "\[PULL REQUEST\]")
    local end_patterns=("</pr-info>" "\[/PR\]" "\[/PULL REQUEST\]")

    # Try different tag formats
    for i in "${!start_patterns[@]}"; do
        start_tag="${start_patterns[$i]}"
        end_tag="${end_patterns[$i]}"

        # Extract content between tags using sed
        pr_info=$(echo "$commit_message" | sed -n "/$start_tag/,/$end_tag/p" | grep -v "$start_tag" | grep -v "$end_tag")

        # If content found, break the loop
        if [ -n "$pr_info" ]; then
            break
        fi
    done

    # If no PR info found, use the entire commit message
    if [ -z "$pr_info" ]; then
        pr_info="$commit_message"
    fi

    # Extract title (first line)
    local title=$(echo "$pr_info" | head -n 1 | xargs)

    # Extract description (everything after the first line)
    local description=$(echo "$pr_info" | tail -n +2)

    # Print results
    echo "Commit SHA: $(git rev-parse HEAD)"
    echo ""
    echo "Pull Request Title:"
    echo "$title"
    echo ""
    echo "Pull Request Description:"
    echo "$description"
}

# Run the function
get_pr_info
