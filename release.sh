#!/bin/bash

# Ensure start and end tags are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <start_tag> <end_tag>" >&2
    exit 1
fi

start_tag="$1"
end_tag="$2"

# Get the full commit message
commit_message=$(git log -1 --pretty=%B)

# Extract content between tags
pr_info=$(echo "$commit_message" | sed -n "/$start_tag/,/$end_tag/p" | grep -v "$start_tag" | grep -v "$end_tag")

# If no PR info found, use the entire commit message
if [ -z "$pr_info" ]; then
    pr_info="$commit_message"
fi

# Extract title (first line)
title=$(echo "$pr_info" | head -n 1 | xargs)

# Extract description (everything after the first line)
description=$(echo "$pr_info" | tail -n +2)

# Print commit SHA
echo "::set-output name=commit_sha::$(git rev-parse HEAD)"

# Print title (for GitHub Actions output)
echo "::set-output name=title::$title"

# Print description (for GitHub Actions output)
echo "::set-output name=description::$description"
