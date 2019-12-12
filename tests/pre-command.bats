#!/usr/bin/env bats

load "$BATS_PATH/load.bash"

# Uncomment to enable stub debugging
# export AWS_STUB_DEBUG=/dev/tty

@test "calls aws sts and exports AWS_ env vars" {
  export BUILDKITE_BUILD_NUMBER="42"
  export BUILDKITE_PLUGIN_AWS_ASSUME_ROLE_ROLE="role123"

  stub aws "sts assume-role \
    --role-arn role123 \
    --role-session-name aws-assume-role-buildkite-plugin-42 \
    --duration-seconds 3600 \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text \
    : \
    echo -e 'foo\tbarr\tbazzz'"

  run $PWD/hooks/pre-command

  assert_output --partial "~~~ Assuming IAM role role123 ..."
  assert_output --partial "AWS session credentials"
  assert_output --partial "AWS_ACCESS_KEY_ID=foo"
  assert_output --partial "AWS_SECRET_ACCESS_KEY=(4 chars)"
  assert_output --partial "AWS_SESSION_TOKEN=(5 chars)"

  assert_success
  unstub aws
}

@test "failure to assume role" {
  export BUILDKITE_BUILD_NUMBER="42"
  export BUILDKITE_PLUGIN_AWS_ASSUME_ROLE_ROLE="role123"

  stub aws "sts assume-role \
    --role-arn role123 \
    --role-session-name aws-assume-role-buildkite-plugin-42 \
    --duration-seconds 3600 \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text \
    : \
    echo 'Not authorized to perform sts:AssumeRole' >&2; false"

  run $PWD/hooks/pre-command

  assert_output <<EOF
~~~ Assuming IAM role role123 ...
Not authorized to perform sts:AssumeRole
EOF
  assert_failure

  unstub aws
}

@test "calls aws sts with custom duration" {
  export BUILDKITE_BUILD_NUMBER="43"
  export BUILDKITE_PLUGIN_AWS_ASSUME_ROLE_ROLE="role123"
  export BUILDKITE_PLUGIN_AWS_ASSUME_ROLE_DURATION="43200"

  stub aws "sts assume-role \
    --role-arn role123 \
    --role-session-name aws-assume-role-buildkite-plugin-43 \
    --duration-seconds 43200 \
    --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]' \
    --output text \
    : \
    echo -e 'a\tbb\tccc'"

  run $PWD/hooks/pre-command

  assert_output --partial "~~~ Assuming IAM role role123 ..."
  assert_output --partial "AWS session credentials"
  assert_output --partial "AWS_ACCESS_KEY_ID=a"
  assert_output --partial "AWS_SECRET_ACCESS_KEY=(2 chars)"
  assert_output --partial "AWS_SESSION_TOKEN=(3 chars)"

  assert_success
  unstub aws
}

@test "passes in a custom region" {
  export BUILDKITE_BUILD_NUMBER="42"
  export BUILDKITE_PLUGIN_AWS_ASSUME_ROLE_ROLE="role123"
  export BUILDKITE_PLUGIN_AWS_ASSUME_ROLE_REGION="eu-central-1"

  stub aws "sts assume-role --role-arn role123 --role-session-name aws-assume-role-buildkite-plugin-42 --duration-seconds 3600 --query Credentials.[AccessKeyId,SecretAccessKey,SessionToken] : echo -e 'a\tb\tc'"

  run $PWD/hooks/pre-command
  assert_output --partial "~~~ Assuming IAM role role123 ..."
  assert_output --partial "AWS_DEFAULT_REGION=eu-central-1"
  assert_output --partial "AWS_REGION=eu-central-1"

  assert_success
  unstub aws
}

@test "does not pass in a custom region" {
  export BUILDKITE_BUILD_NUMBER="42"
  export BUILDKITE_PLUGIN_AWS_ASSUME_ROLE_ROLE="role123"

  stub aws "sts assume-role --role-arn role123 --role-session-name aws-assume-role-buildkite-plugin-42 --duration-seconds 3600 --query Credentials.[AccessKeyId,SecretAccessKey,SessionToken] : echo -e 'a\tb\tc'"

  run $PWD/hooks/pre-command
  assert_output --partial "~~~ Assuming IAM role role123 ..."
  refute_output --partial "AWS_DEFAULT_REGION="
  refute_output --partial "AWS_REGION="

  assert_success
  unstub aws

}
