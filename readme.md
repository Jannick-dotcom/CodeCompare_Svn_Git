# Repository Comparison Script

This script compares a Git repository with an SVN repository using multiple methods:
1. File checksum comparison
2. File diff comparison
3. Commit history comparison

If all comparisons match, the script exits with success (0).  
Any mismatch results in a non-zero exit status.

## Requirements
- `git`
- `svn`
- `sha256sum`
- `diff`
- `xmllint` (from `libxml2-utils`)

## Usage

```bash
./compare.sh <git_repo_url_or_path> <svn_repo_url>
