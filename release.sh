gh pr list --state merged --json number,title,mergedAt,baseRef,targetRef --repo OWNER/REPO | jq -r '
  .[] |
  select(.mergedAt >= "'$(git show -s --format=%ci v1.0 | awk '{print $1}')" and .mergedAt <= "'$(git show -s --format=%ci v2.0 | awk '{print $1}')") |
  "\(.number): \(.title) (merged on \(.mergedAt))"
'
