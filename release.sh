#!/bin/bash

# Set the range for commit comparison between tags
START_TAG="v1.0.0"  # Replace this with your starting tag
END_TAG="v1.1.0"    # Replace this with your ending tag

# Extract all merged pull requests and format the release notes
RELEASE_NOTES=""

# Use git log and loop over each line directly
while IFS= read -r commit_message; do
  # Extract the PR number
  if [[ $commit_message =~ Merge\ pull\ request\ \#([0-9]+).* ]]; then
    pr_number=${BASH_REMATCH[1]}
  else
    pr_number="unknown"
  fi

  # Extract the user-written commit description (the second line in the commit body)
  description=$(echo "$commit_message" | sed -n '2p')

  # Extract author name
  author=$(git log -1 --format='%an')

  # Format the output string
  RELEASE_NOTES+="\n- $description by $author in pull request #$pr_number"
done <<< "$(git log ${START_TAG}..${END_TAG} --merges --pretty=format:'%B')"

# Output the notes
echo -e "$RELEASE_NOTES"
