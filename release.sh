for sha in $(git log v1.0..v2.0 --merges --pretty=format:"%H"); do
  gh pr view --repo OWNER/REPO --json number,title,mergedAt --commit $sha | jq -r '"#\(.number): \(.title) (merged on \(.mergedAt))"'
done
