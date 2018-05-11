AWS AssumeRole Buildkite Plugin
===============================

A [Buildkite plugin](https://buildkite.com/docs/agent/plugins) to assume an IAM Role before running the build command.

Credentials for the assumed role are placed in the environment as `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`, where they will be found by standard AWS tools and SDKs.

The assumed role session expires after one hour, which is the default and maximum duration for the [AssumeRole API](http://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html).

Example
-------


```yaml
steps:
  - command: bin/ci-aws-thing
    plugins:
      cultureamp/aws-assume-role:
        role: arn:aws:iam::123456789012:role/example-role
```

Options
-------

### `role`

The ARN of the IAM Role to assume. The build agent must already be authenticated (e.g. EC2 instance role) and have `sts:AssumeRole` permission for the role being assumed.

References
----------

* [Creating a Role to Delegate Permissions to an IAM User](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-user.html)
* [Requesting Temporary Security Credentials](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_temp_request.html#stsapi_comparison)
* [AWS STS AssumeRole API](http://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html)

License
-------

MIT (see [LICENSE](LICENSE))
