git log v1.0..v2.0 --merges --pretty=format:"%B" | while read -r commit_message; do
  # Assuming user-written title is the first line of commit message
  user_title=$(echo "$commit_message" | head -n 1)
  echo "User-written Title: $user_title"
done
