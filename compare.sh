#!/usr/bin/env bash
set -e

GIT_REPO="$1"
SVN_REPO="$2"
TMP_DIR="$(mktemp -d)"

# Git branches
GIT_BRANCHES=$(git -C "$GIT_REPO" branch -r | sed 's/origin\///')

# SVN branches (standard layout)
SVN_BRANCHES=$(svn list "$SVN_REPO/branches" 2>/dev/null | sed 's#/##')

# Git tags
GIT_TAGS=$(git -C "$GIT_REPO" tag)

# SVN tags (standard layout)
SVN_TAGS=$(svn list "$SVN_REPO/tags" 2>/dev/null | sed 's#/##')

compare_ref() {
    TYPE="$1"     # "branches" or "tags"
    REF="$2"

    GIT_EXPORT="$TMP_DIR/git_${TYPE}_${REF}"
    SVN_EXPORT="$TMP_DIR/svn_${TYPE}_${REF}"

    if [ "$TYPE" = "branches" ]; then
        git clone --depth=1 --branch "$REF" "$GIT_REPO" "$GIT_EXPORT" >/dev/null 2>&1
        SVN_PATH="$SVN_REPO/branches/$REF"
    else
        git clone --depth=1 "$GIT_REPO" "$GIT_EXPORT" >/dev/null 2>&1
        git -C "$GIT_EXPORT" checkout "refs/tags/$REF" >/dev/null 2>&1
        SVN_PATH="$SVN_REPO/tags/$REF"
    fi

    rm -rf "$GIT_EXPORT/.git"

    svn export "$SVN_PATH" "$SVN_EXPORT" >/dev/null 2>&1 || return 1

    # Checksums
    GIT_SUM=$(find "$GIT_EXPORT" -type f -exec sha256sum {} \; | sort)
    SVN_SUM=$(find "$SVN_EXPORT" -type f -exec sha256sum {} \; | sort)
    [ "$GIT_SUM" = "$SVN_SUM" ] || return 2

    # Diff
    diff -qr "$GIT_EXPORT" "$SVN_EXPORT" >/dev/null 2>&1 || return 3

    # History
    if [ "$TYPE" = "branches" ]; then
        GIT_HISTORY=$(git -C "$GIT_REPO" log "$REF" --pretty="%ad %s" --date=iso)
        SVN_HISTORY=$(svn log "$SVN_PATH" --xml | \
            xmllint --xpath "//logentry/concat(date,' ',msg, '\n')" -)
        [ "$GIT_HISTORY" = "$SVN_HISTORY" ] || return 4
    fi
}

# Branches
for BR in $GIT_BRANCHES; do
    echo "Checking branch: $BR"
    if echo "$SVN_BRANCHES" | grep -qx "$BR"; then
        compare_ref "branches" "$BR"
    else
        echo "Branch $BR missing in SVN."
        exit 1
    fi
done

# Tags
for TG in $GIT_TAGS; do
    echo "Checking tag: $TG"
    if echo "$SVN_TAGS" | grep -qx "$TG"; then
        compare_ref "tags" "$TG"
    else
        echo "Tag $TG missing in SVN."
        exit 1
    fi
done

echo "Success: All branches and tags match."
exit 0
