#!/usr/bin/env bash

set -e

GIT_REPO="$1"
SVN_REPO="$2"
TMP_DIR="$(mktemp -d)"

GIT_EXPORT="$TMP_DIR/git"
SVN_EXPORT="$TMP_DIR/svn"

# Export Git
git clone --depth=1 "$GIT_REPO" "$GIT_EXPORT" >/dev/null 2>&1
rm -rf "$GIT_EXPORT/.git"

# Export SVN
svn export "$SVN_REPO" "$SVN_EXPORT" >/dev/null 2>&1

# Method 1: Checksums
GIT_SUM=$(find "$GIT_EXPORT" -type f -exec sha256sum {} \; | sort)
SVN_SUM=$(find "$SVN_EXPORT" -type f -exec sha256sum {} \; | sort)

if [ "$GIT_SUM" != "$SVN_SUM" ]; then
    echo "Mismatch detected by checksum comparison."
    exit 1
fi

# Method 2: File diff
diff -qr "$GIT_EXPORT" "$SVN_EXPORT" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Mismatch detected by diff comparison."
    exit 1
fi

# Method 3: History comparison
GIT_HISTORY=$(git -C "$GIT_REPO" log --pretty="%ad %s" --date=iso | sed 's/  / /g')
SVN_HISTORY=$(svn log "$SVN_REPO" --xml | \
    xmllint --xpath "//logentry/concat(date,' ',msg, '\n')" -)

if [ "$GIT_HISTORY" != "$SVN_HISTORY" ]; then
    echo "Mismatch detected in history comparison."
    exit 1
fi

echo "Success: Repositories and histories match."
exit 0
