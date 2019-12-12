AWS AssumeRole Buildkite Plugin
===============================

A [Buildkite plugin](https://buildkite.com/docs/agent/plugins) to assume an IAM Role before running the build command.

Credentials for the assumed role are placed in the environment as `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, where they will be found by standard AWS tools and SDKs.

The assumed role session expires after one hour, which is the default and maximum duration for the [AssumeRole API](http://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html).

Example
-------


```yml
steps:
  - command: bin/ci-aws-thing
    plugins:
      - cultureamp/aws-assume-role#v0.1.0:
          role: "arn:aws:iam::123456789012:role/example-role"
```

Alternatively, you could specify `AWS_ASSUME_ROLE_ARN` in your environment

```yaml
steps:
  - command: bin/ci-aws-thing
    env:
      AWS_ASSUME_ROLE_ARN: arn:aws:iam::123456789012:role/example-role
    plugins:
      - cultureamp/aws-assume-role
```

Options
-------

### `role`

The ARN of the IAM Role to assume. The build agent must already be authenticated (e.g. EC2 instance role) and have `sts:AssumeRole` permission for the role being assumed.

### `duration` (optional)

The duration (in seconds) to assume the role for. Defaults to 3600 (1 hour).

### `region` (optional)

Exports `AWS_REGION` and `AWS_DEFAULT_REGION` with the value you set. If not set the values of AWS_REGION and AWS_DEFAULT_REGION will not be changed.

Development
-----------

Tests are written using bats with bats-mock and a docker compose file is provided to simplify testing.
To run tests: `docker-compose run tests`

References
----------

* [Creating a Role to Delegate Permissions to an IAM User](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user.html)
* [Requesting Temporary Security Credentials](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison)
* [AWS STS AssumeRole API](http://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html)
* [Checking the Maximum Session Duration for a Role](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html#id_roles_use_view-role-max-session)

License
-------

MIT (see [LICENSE](LICENSE))
