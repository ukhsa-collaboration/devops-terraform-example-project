module "aws-oidc-github" {
  source = "git::ssh://git@github.com/UKHSA-Internal/devops-terraform-modules.git?ref=8e2891e661b95fe30d9bd3b42ccc80e4c356f16a"

  repo_name = "UKHSA-Internal/devops-terraform-example-project"
  additional_allowed_repos = {
    "UKHSA-Internal/devops-github-reusable-workflows" = {
      aud : var.allowed_audience
    }
  }
  allowed_refs = var.allowed_audience
}