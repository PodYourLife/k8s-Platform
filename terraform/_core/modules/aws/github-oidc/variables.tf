variable "cluster_name" {
  description = "Cluster name — used as prefix for IAM role names"
  type        = string
}

variable "github_org" {
  description = "GitHub organization that owns the repository, exactly as GitHub spells it (e.g. PodYourLife)."
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z0-9-]+$", var.github_org))
    error_message = "github_org must be a literal organization name: no wildcard or separator."
  }
}

variable "github_repository" {
  description = <<-EOT
    Repository name (without organization prefix) trusted to assume the CI roles.
    Case-sensitive: it must match the name GitHub puts in the OIDC sub claim
    exactly (e.g. k8s-Platform). A single repository, no wildcard.
  EOT
  type        = string
  validation {
    condition     = can(regex("^[A-Za-z0-9._-]+$", var.github_repository))
    error_message = "github_repository must be a literal repository name: no wildcard or separator."
  }
}

variable "aws_region" {
  description = "AWS region — used in IAM policy resource ARNs"
  type        = string
}

variable "state_bucket" {
  description = "S3 bucket name for Terraform state — scoped in apply policy"
  type        = string
}

variable "lock_table" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
}

variable "environment" {
  description = "Environment of the roles. The OIDC trust accepts only jobs running under the GitHub Environment of the same name."
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "aws_account_id" {
  description = "AWS account ID — used in IAM policy resource ARNs for DynamoDB lock table"
  type        = string
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}
