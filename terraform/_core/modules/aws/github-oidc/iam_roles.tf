# iam_roles.tf
# Resources: aws_iam_role, aws_iam_policy, aws_iam_role_policy_attachment
#
# One pair of roles per environment. Both roles trust exactly one OIDC subject:
# a job of the trusted repository running under the GitHub Environment named
# after var.environment. StringEquals only: no StringLike, no wildcard, and no
# subject from another environment (a dev job must never assume prod roles).
# Jobs must declare `environment: <env>`; GitHub then emits
# sub = repo:<org>/<repo>:environment:<env>.

locals {
  oidc_subject = "repo:${var.github_org}/${var.github_repository}:environment:${var.environment}"

  oidc_trust_condition = {
    StringEquals = {
      "token.actions.githubusercontent.com:sub" = local.oidc_subject
      "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
    }
  }
}

# ── Terraform plan role — read-only, environment-scoped ───────────────────────

resource "aws_iam_role" "terraform_plan" {
  name = "${var.cluster_name}-github-terraform-plan"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Condition = local.oidc_trust_condition
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "terraform_plan_readonly" {
  role       = aws_iam_role.terraform_plan.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# terraform plan must acquire the DynamoDB state lock (PutItem/DeleteItem)
# and read the S3 state object. ReadOnlyAccess covers the S3 read path but
# not the DynamoDB write path, so grant only the lock-table actions here.
resource "aws_iam_role_policy" "terraform_plan_state_lock" {
  name = "${var.cluster_name}-terraform-plan-state-lock"
  role = aws_iam_role.terraform_plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "StateLock"
      Effect = "Allow"
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:DescribeTable",
      ]
      Resource = "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/${var.lock_table}"
    }]
  })
}

# ── Terraform apply role — environment-scoped ────────────────────────────────
# Same subject as the plan role: the GitHub Environment protection rules of
# <env> (required reviewers, branch policy) gate every apply.

resource "aws_iam_role" "terraform_apply" {
  name = "${var.cluster_name}-github-terraform-apply"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRoleWithWebIdentity"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Condition = local.oidc_trust_condition
    }]
  })

  tags = var.tags
}

resource "aws_iam_policy" "terraform_apply" {
  name        = "${var.cluster_name}-github-terraform-apply-policy"
  description = "Permissions for Terraform apply via GitHub Actions CI — ${var.environment} environment only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformStateBackend"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable",
        ]
        Resource = [
          "arn:aws:s3:::${var.state_bucket}",
          "arn:aws:s3:::${var.state_bucket}/*",
          "arn:aws:dynamodb:${var.aws_region}:${var.aws_account_id}:table/${var.lock_table}",
        ]
      },
      {
        Sid    = "EKSManagement"
        Effect = "Allow"
        Action = [
          "eks:*",
          "ec2:*",
          "iam:*",
          "autoscaling:*",
          "elasticloadbalancing:*",
          "cloudwatch:*",
          "logs:*",
          "secretsmanager:*",
          "kms:*",
          "ssm:*",
        ]
        Resource = ["*"]
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "terraform_apply" {
  role       = aws_iam_role.terraform_apply.name
  policy_arn = aws_iam_policy.terraform_apply.arn
}
