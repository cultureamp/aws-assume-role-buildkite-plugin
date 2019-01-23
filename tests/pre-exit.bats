#!/usr/bin/env bats

load "$BATS_PATH/load.bash"

# Uncomment to enable stub debugging
# export AWS_STUB_DEBUG=/dev/tty


@test "unsets AWS env vars" {
    export BUILDKITE_BUILD_NUMBER="42"
    export BUILDKITE_PLUGIN_AWS_ASSUME_ROLE_ROLE="role123"

    stub aws "sts assume-role --role-arn role123 --role-session-name aws-assume-role-buildkite-plugin-42 --duration-seconds 3600 --query Credentials : cat tests/sts.json"

    run $PWD/hooks/post-checkout

    assert_output --partial "~~~ :aws-iam: Assuming IAM role"
    assert_output --partial "Role: role123"
    assert_output --partial "Exported session credentials"
    assert_output --partial "AWS_ACCESS_KEY_ID=baz"
    assert_output --partial "AWS_SECRET_ACCESS_KEY=(3 chars)"
    assert_output --partial "AWS_SESSION_TOKEN=(3 chars)"

    assert_success

    run $PWD/hooks/pre-exit

    assert_output --partial "~~~ :aws-iam: Cleaning IAM role environment"

    assert_success
    unstub aws
}
