module "iam_github_oidc_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
  version = "5.47.1"
}

module "iam_github_oidc_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.47.1"

  name = "github-actions-oidc"

  subjects = [
    "repo:ukhsa-collaboration/devops-terraform-example-project:environment:${var.environment_name}",
    "repo:ukhsa-collaboration/devops-github-reusable-workflows:environment:${var.environment_name}",
    "repo:UKHSA-Internal/devops-terraform-example-project:environment:dev",
    "repo:UKHSA-Internal/devops-github-reusable-workflows:environment:dev"
  ]

  policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }
}