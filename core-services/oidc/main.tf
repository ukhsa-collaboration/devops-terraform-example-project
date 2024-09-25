module "aws-oidc-github" {
  source = "git::ssh://git@github.com/UKHSA-Internal/devops-terraform-modules//terraform-modules/aws/oidc?ref=0491d5442d3e97d71a63dd14bfdc69a66e67551a"

  repo_name = "UKHSA-Internal/devops-terraform-example-project"
  additional_allowed_repos = {
    "UKHSA-Internal/devops-github-reusable-workflows" = {
      aud : var.allowed_audience
    }
  }
  allowed_refs = var.allowed_audience
}
