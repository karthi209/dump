#!/bin/bash

# Function to extract PR info from the latest commit
get_pr_info() {
    # Check if start and end tags are provided
    if [ $# -ne 2 ]; then
        echo "Usage: $0 <start_tag> <end_tag>" >&2
        return 1
    }

    local start_tag="$1"
    local end_tag="$2"

    # Ensure we're in a git repository
    if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
        echo "Error: Not in a Git repository" >&2
        return 1
    fi

    # Get the full commit message
    local commit_message=$(git log -1 --pretty=%B)

    # Extract content between tags using sed
    local pr_info=$(echo "$commit_message" | sed -n "/$start_tag/,/$end_tag/p" | grep -v "$start_tag" | grep -v "$end_tag")

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

# Run the function with passed arguments
get_pr_info "$@"
