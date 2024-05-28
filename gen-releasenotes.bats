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
@test "Generates release notes: No tag - All commits" {
    cd "$REPO"
    git init -b master
    git commit --allow-empty -m 'First commit'
    git commit --allow-empty -m 'Second commit'
    git commit --allow-empty -m 'Third commit'

    run "$BATS_TEST_DIRNAME/gen-releasenotes.sh"
    [ "$status" = 0 ]
    cat "$REPO/changelog.md" | grep -E 'First commit|Second commit|Third commit'
    [ "$( cat "$REPO/changelog.md" | wc -l )" = 3 ]
}
@test "Generates release notes: No tag - SHA to SHA" {
    cd "$REPO"
    git init -b master
    git commit --allow-empty -m 'First commit'
    git commit --allow-empty -m 'Second commit'
    git commit --allow-empty -m 'Third commit'
    SHA_SECOND_COMMIT=$( git --no-pager log --oneline --no-decorate --reverse --format='%h' | head -n2 | tail -n1 )
    SHA_FIRST_COMMIT=$( git --no-pager log --oneline --no-decorate --reverse --format='%h' | head -n1 )

    run "$BATS_TEST_DIRNAME/gen-releasenotes.sh" -a "$SHA_SECOND_COMMIT" -b "$SHA_FIRST_COMMIT"
    [ "$status" = 0 ]
    cat "$REPO/changelog.md" | grep -E 'First commit|Second commit'
    [ "$( cat "$REPO/changelog.md" | wc -l )" = 2 ]
}
@test "Generates release notes: 1 tag - HEAD and tag" {
    cd "$REPO"
    git init -b master
    git commit --allow-empty -m 'First commit'
    git tag v0.1.0
    git commit --allow-empty -m 'Second commit'
    git commit --allow-empty -m 'Third commit'

    run "$BATS_TEST_DIRNAME/gen-releasenotes.sh"
    [ "$status" = 0 ]
    cat "$REPO/changelog.md" | grep -E 'Second commit|Third commit'
    [ "$( cat "$REPO/changelog.md" | wc -l )" = 2 ]
}
@test "Generates release notes: 1 tag - latest tag and first commit" {
    cd "$REPO"
    git init -b master
    git commit --allow-empty -m 'First commit'
    git commit --allow-empty -m 'Second commit'
    git commit --allow-empty -m 'Third commit'
    git tag v0.1.0

    run "$BATS_TEST_DIRNAME/gen-releasenotes.sh" -a v0.1.0
    [ "$status" = 0 ]
    cat "$REPO/changelog.md" | grep -E 'First commit|Second commit|Third commit'
    [ "$( cat "$REPO/changelog.md" | wc -l )" = 3 ]
}
@test "Generates release notes: 2 tags - HEAD and latest tag" {
    cd "$REPO"
    git init -b master
    git commit --allow-empty -m 'First commit'
    git tag v0.1.0
    git commit --allow-empty -m 'Second commit'
    git tag v0.2.0
    git commit --allow-empty -m 'Third commit'

    run "$BATS_TEST_DIRNAME/gen-releasenotes.sh"
    [ "$status" = 0 ]
    cat "$REPO/changelog.md" | grep -E 'Third commit'
    [ "$( cat "$REPO/changelog.md" | wc -l )" = 1 ]
}
@test "Generates release notes: 2 tags - Latest tag and previous tag" {
    cd "$REPO"
    git init -b master
    git commit --allow-empty -m 'First commit'
    git tag v0.1.0
    git commit --allow-empty -m 'Second commit'
    git tag v0.2.0
    git commit --allow-empty -m 'Third commit'

    run "$BATS_TEST_DIRNAME/gen-releasenotes.sh" -a v0.2.0 -b v0.1.0
    [ "$status" = 0 ]
    cat "$REPO/changelog.md" | grep -E 'Second commit'
    [ "$( cat "$REPO/changelog.md" | wc -l )" = 1 ]
}
@test "Generates release notes: Using --repo" {
    cd "$REPO"
    git init -b master
    git commit --allow-empty -m 'First commit'
    git commit --allow-empty -m 'Second commit'
    git commit --allow-empty -m 'Third commit'
    cd -

    run "$BATS_TEST_DIRNAME/gen-releasenotes.sh" --repo "$REPO"
    [ "$status" = 0 ]
    cat "$REPO/changelog.md" | grep -E 'First commit|Second commit|Third commit'
    [ "$( cat "$REPO/changelog.md" | wc -l )" = 3 ]
}
@test "Generates release notes: Using --output" {
    cd "$REPO"
    git init -b master
    git commit --allow-empty -m 'First commit'
    git commit --allow-empty -m 'Second commit'
    git commit --allow-empty -m 'Third commit'

    run "$BATS_TEST_DIRNAME/gen-releasenotes.sh" --output somefile.md
    [ "$status" = 0 ]
    cat "$REPO/somefile.md" | grep -E 'First commit|Second commit|Third commit'
    [ "$( cat "$REPO/somefile.md" | wc -l )" = 3 ]
}
