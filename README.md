## Terraform Module for creating OIDC IDP and IAM Role for GitLab Pipelines workflows to assume

This terraform module creates an OIDC Identity Provider and IAM role inside the target account that allows GitLab pipeliens to assume that role inside the workflow. This allows for usage of the organizational runners that are setup and reduce operational overhead and cost while ensuring account safety by specifying down to a repo and branch.

## Trust policy

The trust policy can be a little confusing, so the regex is the following. The `repo:x` is what you need to enter in your terraform variables:

`"project_path:mygroup/myproject:ref_type:branch:ref:main"`
`"project_path:mygroup/myproject:*"`

- You can use `"project_path:mygroup/*` to assume the role from any repo under the group level.
- You can use `"project_path:mygroup/myproject:*"` to allow access from any branch in sample\_project in sample\_group to assume the role.
- You can use `"project_path:mygroup/myproject:ref_type:branch:ref:main"` to allow access from the main branch in sample\_project in sample\_group to assume the role.

## Least permissions by default

The IAM role that is created comes with no policies attached. This means you will need to assign any permissions you want the role to have in the format of `name = "<policy_arn>"`. eg `s3 = "arn:aws:iam::aws:policy/AmazonS3FullAccess"`.

## Sample .gitlab-ci.yaml to assume the role

```yaml
assume_role:
  variables:
    ROLE_ARN: arn:aws:iam::<your_account>:role/GitLabPipelineRole
  id_tokens:
    GITLAB_OIDC_TOKEN:
      aud: sts.amazonaws.com
  before_script:
    - apk add --no-cache aws-cli
  script:
    - >
      export $(printf "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s"
      $(aws sts assume-role-with-web-identity
      --role-arn ${ROLE_ARN}
      --role-session-name "GitLabRunner-${CI_PROJECT_ID}-${CI_PIPELINE_ID}"
      --web-identity-token ${GITLAB_OIDC_TOKEN}
      --duration-seconds 3600
      --query 'Credentials.[AccessKeyId,SecretAccessKey,SessionToken]'
      --output text))
    - aws sts get-caller-identity # This just shows you've assumed the role, can be ommitted
```
