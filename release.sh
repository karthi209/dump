#!/bin/bash

# Set the range for comparison between tags
START_TAG="v1.0.0"  # Replace with your starting tag
END_TAG="v1.1.0"    # Replace with your ending tag

# Extract merged pull requests and their formatted data, excluding empty commit messages
RELEASE_NOTES=""
while IFS= read -r commit_message; do
  # Skip if the commit message is empty
  if [[ -z "$commit_message" ]]; then
    continue
  fi

  # Extract the PR number from the commit hash
  pr_number=$(echo "$commit_message" | sed -n 's/.*pull request \([0-9]*\)/\1/p')

  # Format the release notes line
  RELEASE_NOTES+="\n- ${commit_message} - PR #${pr_number}"
done < <(git log ${START_TAG}..${END_TAG} --merges --pretty=format:"%b in pull request %H")

# Output the notes
echo -e "$RELEASE_NOTES"
