NOTES=$(git log ${{ github.event.before }}..${{ github.ref }} --merges --pretty=format:"- %s by %an in pull request %H")
