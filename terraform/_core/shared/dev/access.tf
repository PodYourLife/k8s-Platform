# access.tf
# Responsibility: CI access via GitHub Actions OIDC.
#
# IAM Identity Center (permission sets, groups, account assignments) is managed
# in domains/organization — not here. Each env account is self-contained.
#
# IdP is currently AWS IAM Identity Center standalone (free, zero friction).
# To switch to Okta/Google/Keycloak: configure external IdP in IAM Identity Center
# console and enable SCIM provisioning — this file stays unchanged.

# ── GitHub Actions OIDC ────────────────────────────────────────────────────────
# Allows CI to assume AWS roles without storing static credentials in GitHub.
# plan and apply roles → jobs running under the GitHub Environment named
# after this environment only (exact OIDC subject, see the module).

module "github_oidc" {
  source = "../../modules/aws/github-oidc"

  cluster_name      = var.cluster_name
  github_org        = var.github_org
  github_repository = var.github_repository
  aws_region        = var.aws_region
  aws_account_id    = var.aws_account_id
  environment       = var.environment
  state_bucket      = "k8s-platform-terraform-state-${var.aws_account_id}"
  lock_table        = "k8s-platform-terraform-locks"

  tags = {
    Environment = var.environment
    Component   = "ci-access"
  }
}
