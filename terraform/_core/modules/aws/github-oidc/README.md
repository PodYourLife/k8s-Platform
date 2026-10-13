# Module: github-oidc

Configures GitHub Actions as a trusted OIDC identity provider in AWS. Provisions two IAM roles for one environment — `terraform plan` (read-only) and `terraform apply`.

Both roles trust exactly one subject, with `StringEquals` only (no `StringLike`, no wildcard):

```
token.actions.githubusercontent.com:sub = repo:<github_org>/<github_repository>:environment:<environment>
token.actions.githubusercontent.com:aud = sts.amazonaws.com
```

A job can assume these roles only if it runs under the GitHub Environment named after `environment`, so that environment's protection rules gate every plan and apply. A job of another environment (for example `dev`) can never assume the `prod` roles. See ADR-0008.

> [!IMPORTANT]
> `StringEquals` is case-sensitive. `github_repository` must match the repository name exactly as GitHub emits it in the `sub` claim (`k8s-Platform`, not `k8s-platform`). If the organization or repository enables a customized or immutable subject claim format, the expected `sub` changes and this module must be updated first.

No static credentials are stored in GitHub. The only GitHub secret is the role ARN.

## How it works

```
GitHub Actions workflow
  → requests OIDC token from GitHub
  → calls sts:AssumeRoleWithWebIdentity with token
  → AWS validates token against registered OIDC provider
  → returns temporary credentials (1h)
```

## Usage

```hcl
module "github_oidc" {
  source = "../../modules/github-oidc"

  cluster_name      = var.cluster_name
  github_org        = "PodYourLife"
  github_repository = "k8s-Platform"
  environment       = var.environment
  aws_region        = var.aws_region
  aws_account_id    = var.aws_account_id
  state_bucket      = var.state_bucket
  lock_table        = var.lock_table
}
```

After apply, set these in GitHub → Settings → Secrets:

```
AWS_TERRAFORM_PLAN_ROLE_ARN  = <module.github_oidc.plan_role_arn>
AWS_TERRAFORM_ROLE_ARN       = <module.github_oidc.apply_role_arn>
```

In workflows, every job that assumes a role must declare the environment:

```yaml
jobs:
  apply:
    environment: prod          # required: sets sub = repo:PodYourLife/k8s-Platform:environment:prod
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_TERRAFORM_ROLE_ARN }}
          aws-region: ${{ vars.AWS_REGION }}
```

## Files

| File | Resources |
|------|-----------|
| `oidc_provider.tf` | `data.tls_certificate` (GitHub), `aws_iam_openid_connect_provider` |
| `iam_roles.tf` | `aws_iam_role` × 2 (plan + apply), `aws_iam_policy`, `aws_iam_role_policy_attachment` × 2 |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| aws | ~> 5.0 |
| tls | ~> 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `cluster_name` | Cluster name — used as IAM role name prefix | `string` | — | yes |
| `github_org` | GitHub organization, exact spelling (e.g. `PodYourLife`) | `string` | — | yes |
| `github_repository` | Trusted repository, case-sensitive (e.g. `k8s-Platform`) | `string` | — | yes |
| `environment` | `dev`, `staging` or `prod` — the only GitHub Environment trusted | `string` | — | yes |
| `aws_region` | AWS region — scoped in apply policy resource ARNs | `string` | — | yes |
| `aws_account_id` | AWS account ID — scoped in the lock table ARN | `string` | — | yes |
| `state_bucket` | S3 bucket name for Terraform state | `string` | — | yes |
| `lock_table` | DynamoDB table name for state locking | `string` | — | yes |
| `tags` | Tags applied to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `plan_role_arn` | IAM role ARN for plan — set as `AWS_TERRAFORM_PLAN_ROLE_ARN` in GitHub secrets |
| `apply_role_arn` | IAM role ARN for apply — set as `AWS_TERRAFORM_ROLE_ARN` in GitHub secrets |
| `oidc_provider_arn` | GitHub OIDC provider ARN |
