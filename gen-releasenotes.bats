setup() {
    REPO="$BATS_TEST_TMPDIR/repo"
    mkdir -p "$REPO"
}
teardown() {
    :
}
@test "Prints usage" {
    run ./gen-releasenotes.sh --help
    [ "$status" = 0 ]
    echo "$output" | grep gen-releasenotes.sh
}
@test "Generates release notes for --repo between HEAD and first commit" {
    (
        cd "$REPO"
        git init -b master
        git commit --allow-empty -m 'First commit'
        git commit --allow-empty -m 'Second commit'
        git commit --allow-empty -m 'Third commit'
    )

    run ./gen-releasenotes.sh --repo "$REPO"
    cat "$REPO/changelog.md"
    [ "$status" = 0 ]
    [ "$( cat "$REPO/changelog.md" | grep -E 'First commit|Second commit|Third commit' | wc -l )" = 3 ]
}
@test "Generates release notes for --repo between HEAD and tag" {
    (
        cd "$REPO"
        git init -b master
        git commit --allow-empty -m 'First commit'
        git tag v0.1.0
        git commit --allow-empty -m 'Second commit'
        git commit --allow-empty -m 'Third commit'
    )

    run ./gen-releasenotes.sh --repo "$REPO"
    [ "$status" = 0 ]
    [ "$( cat "$REPO/changelog.md" | grep -E 'Second commit|Third commit' | wc -l )" = 2 ]
}
