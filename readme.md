# Repository Comparison Script

This script compares a Git repository with an SVN repository across:
1. File checksums
2. File diffs
3. Commit history (for branches)
4. All branches
5. All tags

If all comparisons match, the script exits with code 0.  
Any mismatch triggers a non-zero exit.

## Requirements
- `git`
- `svn`
- `sha256sum`
- `diff`
- `xmllint` (from `libxml2-utils`)

## Usage

```bash
./compare.sh <git_repo_url_or_path> <svn_repo_url>
