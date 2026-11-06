#!/usr/bin/env bats

load "$BATS_PATH/load.bash"

# Uncomment to enable stub debugging
# export AWS_STUB_DEBUG=/dev/tty

setup() {
  export BUILDKITE_PIPELINE_SLUG="my-pipeline"
  export BUILDKITE_STEP_KEY="deploy"
  export BUILDKITE_JOB_ID="0190a1b2-c3d4-4e5f-8a9b-0c1d2e3f4a5b"
}

@test "calls aws sts and exports AWS_ env vars" {
  export BUILDKITE_BUILD_NUMBER="42"
  export BUILDKITE_PLUGIN_AWS_ASSUME_ROLE_ROLE="role123"

  stub aws "sts assume-role --role-arn role123 --role-session-name bk-my-pipeline-42-deploy --duration-seconds 3600 --query Credentials : cat tests/sts.json"

  run $PWD/hooks/pre-command

  assert_output --partial "~~~ Assuming IAM role role123 ..."
  assert_output --partial "Exported session credentials"
  assert_output --partial "AWS_ACCESS_KEY_ID=baz"
  assert_output --partial "AWS_SECRET_ACCESS_KEY=(3 chars)"
  assert_output --partial "AWS_SESSION_TOKEN=(3 chars)"

  assert_success
  unstub aws
}

@test "falls back to the job id when there is no step key" {
  export BUILDKITE_BUILD_NUMBER="42"
  export BUILDKITE_PLUGIN_AWS_ASSUME_ROLE_ROLE="role123"
  unset BUILDKITE_STEP_KEY

  stub aws "sts assume-role --role-arn role123 --role-session-name bk-my-pipeline-42-0190a1b2-c3d4-4e5f-8a9b-0c1d2e3f4a5b --duration-seconds 3600 --query Credentials : cat tests/sts.json"

  run $PWD/hooks/pre-command

  assert_success
  unstub aws
}

@test "replaces characters STS rejects in the session name" {
  export BUILDKITE_BUILD_NUMBER="42"
  export BUILDKITE_PLUGIN_AWS_ASSUME_ROLE_ROLE="role123"
  export BUILDKITE_STEP_KEY="deploy:prod"

  stub aws "sts assume-role --role-arn role123 --role-session-name bk-my-pipeline-42-deploy_prod --duration-seconds 3600 --query Credentials : cat tests/sts.json"

  run $PWD/hooks/pre-command

  assert_success
  unstub aws
}

@test "truncates the pipeline slug to keep the session name within 64 chars" {
  export BUILDKITE_BUILD_NUMBER="42"
  export BUILDKITE_PLUGIN_AWS_ASSUME_ROLE_ROLE="role123"
  export BUILDKITE_PIPELINE_SLUG="a-very-long-pipeline-slug-that-would-overflow-the-session-name"
  unset BUILDKITE_STEP_KEY

  stub aws "sts assume-role --role-arn role123 --role-session-name bk-a-very-long-pipeline--42-0190a1b2-c3d4-4e5f-8a9b-0c1d2e3f4a5b --duration-seconds 3600 --query Credentials : cat tests/sts.json"

  run $PWD/hooks/pre-command

  assert_success
  unstub aws
}

@test "failure to assume role" {
  export BUILDKITE_BUILD_NUMBER="42"
  export BUILDKITE_PLUGIN_AWS_ASSUME_ROLE_ROLE="role123"

  stub aws "sts assume-role --role-arn role123 --role-session-name bk-my-pipeline-42-deploy --duration-seconds 3600 --query Credentials : echo 'Not authorized to perform sts:AssumeRole' >&2; false"

  run $PWD/hooks/pre-command

  assert_output <<EOF
~~~ Assuming IAM role role123 ...
Not authorized to perform sts:AssumeRole
EOF
  assert_failure

  unstub aws
}

@test "calls aws sts with custom duration" {
  export BUILDKITE_BUILD_NUMBER="42"
  export BUILDKITE_PLUGIN_AWS_ASSUME_ROLE_ROLE="role123"
  export BUILDKITE_PLUGIN_AWS_ASSUME_ROLE_DURATION="43200"

  stub aws "sts assume-role --role-arn role123 --role-session-name bk-my-pipeline-42-deploy --duration-seconds 43200 --query Credentials : cat tests/sts.json"

  run $PWD/hooks/pre-command

  assert_output --partial "~~~ Assuming IAM role role123 ..."
  assert_output --partial "Exported session credentials"
  assert_output --partial "AWS_ACCESS_KEY_ID=baz"
  assert_output --partial "AWS_SECRET_ACCESS_KEY=(3 chars)"
  assert_output --partial "AWS_SESSION_TOKEN=(3 chars)"

  assert_success
  unstub aws
}

@test "passes in a custom region" {
  export BUILDKITE_BUILD_NUMBER="42"
  export BUILDKITE_PLUGIN_AWS_ASSUME_ROLE_ROLE="role123"
  export BUILDKITE_PLUGIN_AWS_ASSUME_ROLE_REGION="eu-central-1"

  stub aws "sts assume-role --role-arn role123 --role-session-name bk-my-pipeline-42-deploy --duration-seconds 3600 --query Credentials : cat tests/sts.json"

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

  stub aws "sts assume-role --role-arn role123 --role-session-name bk-my-pipeline-42-deploy --duration-seconds 3600 --query Credentials : cat tests/sts.json"

  run $PWD/hooks/pre-command
  assert_output --partial "~~~ Assuming IAM role role123 ..."
  refute_output --partial "AWS_DEFAULT_REGION="
  refute_output --partial "AWS_REGION="

  assert_success
  unstub aws

}
