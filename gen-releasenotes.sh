#!/bin/sh
set -eu

usage() {
    cat - <<EOF
Usage: ./$( basename "$0" ) [OPTIONS]
Subcommands:
Options:
    -r|--repo                 Repo
    -v|--verbose              Verbose
Examples:
EOF
}

# Exit if we got no options
if [ $# -eq 0 ]; then usage; exit 1; fi

# Get some options
while test $# -gt 0; do
    case "$1" in
        -a|--ref-start)
            shift
            REF_START="$1"
            shift
            ;;
        -b|--ref-end)
            shift
            REF_END="$1"
            shift
            ;;
        -r|--repo)
            shift
            REPO="$1"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        *)
            DIR="$1"
            shift
            ;;
    esac
done

# Configuration
REF_START=${REF_START:-HEAD}
REF_END=${REF_END:-}
REPO=${REPO:?err}

# Validation
if [ ! -d "$REPO" ]; then
    echo "$REPO specified by --repo is not a directory"
    exit 1
fi

cd "$REPO"
echo "REPO=$REPO"

# Get tags
TAGS=$( git --no-pager tag -l --sort=-version:refname )
TAGS_COUNT=0
if [ -n "$TAGS" ]; then
    echo "$TAGS" | wc -l
fi
echo "Found $TAGS_COUNT tags"
echo "TAGS=$TAGS"

# Determine ref range
if [ "$TAGS_COUNT" = 0 ]; then
    REF_START="$REF_START"
    REF_END=$( git --no-pager log --oneline --no-decorate --reverse --format='%h' | head -n1 )  # First commit's ref
    RANGE="$REF_START"
    echo "No tag found. Will parse between $REF_START and $REF_END"
elif [ "$TAGS_COUNT" = 1 ]; then
    if [ "$REF_START" = "$( echo "$TAGS" | head -n1 )" ]; then
        REF_START="$REF_START"
        REF_END=$( git --no-pager log --oneline --no-decorate --reverse -1 --format='%h' | head -n1 )  # First commit's ref
    else
        REF_START="$REF_START"
        REF_END=$( echo "$TAGS" | head -n1 )
    fi
    RANGE="$REF_START...$REF_END"
    echo "1 tag found. Will parse between $REF_START and $REF_END"
elif [ "$TAGS_COUNT" -gt 1 ]; then
    if [ "$REF_START" = "$( echo "$TAGS" | head -n1 )" ]; then
        REF_START="$REF_START"
        REF_END=$( echo "$TAGS" | head -n2 | tail -n1 ) # Second most recent tag
    else
        REF_START="$REF_START"
        REF_END=$( echo "$TAGS" | head -n1 )
    fi
    RANGE="$REF_START...$REF_END"
    echo "2 or more tags found. Will parse between $REF_START and $REF_END"
fi

# echo "REF_START=$REF_START"
# echo "REF_END=$REF_END"
# set -x
REF_START_SHA=$(
    if [ "$REF_START" = 'HEAD' ]; then
        git show-ref --head --abbrev --hash "$REF_START" | head -n1 || true
    else
        git show-ref --abbrev --hash "$REF_START" | head -n1 || true
    fi
)
if [ -z "$REF_START_SHA" ]; then
    REF_START_SHA="$REF_START"
fi
REF_END_SHA=$(
    if [ "$REF_END" = 'HEAD' ]; then
        git show-ref --head --abbrev --hash "$REF_END" | head -n1 || true
    else
        git show-ref --abbrev --hash "$REF_END" | head -n1 || true
    fi
)
if [ -z "$REF_END_SHA" ]; then
    REF_END_SHA="$REF_END"
fi
echo "REF_START_SHA=$REF_START_SHA"
echo "REF_END_SHA=$REF_END_SHA"
if [ "$REF_START_SHA" = "$REF_END_SHA" ]; then
    echo "--ref-start's SHA '$REF_START_SHA' is identical to --ref-end's SHA '$REF_END_SHA'"
    exit 1
fi

# set -x
if ! git rev-parse --show-toplevel > /dev/null 2>&1; then
    echo "$REPO is not a git repo. Create a repo using: git init -b master; git commit -m 'Init' --allow-empty"
    exit 1
fi

COMMITS=$( git --no-pager log "$RANGE" --format="%B" --oneline --no-decorate )
COMMITS_MERGES=$( git --no-pager log "$RANGE" --format="%B" --oneline --no-decorate --merges )
COMMITS_NOMERGES=$( git --no-pager log "$RANGE" --format="%B" --oneline --no-decorate --no-merges )

echo "Generating release notes: $REPO/changelog.md"
echo "$COMMITS" > "$REPO/changelog.md"
