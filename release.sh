for sha in $(git log v1.0..v2.0 --merges --pretty=format:"%H"); do
  gh pr list --state merged --search "$sha" --json number,title,mergedAt --repo OWNER/REPO | \
  jq -r '"#\(.number): \(.title) (merged on \(.mergedAt))"'
done
