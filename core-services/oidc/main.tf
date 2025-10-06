module "iam_github_oidc_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-oidc-provider"
  version = "6.0.0"

  url = "https://token.actions.githubusercontent.com"
}

### The github-actions-oidc role is used to deploy Terraform code.
module "iam_github_oidc_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.0.0"

  name            = "github-actions-oidc"
  use_name_prefix = false

  enable_github_oidc = true

  oidc_subjects = [
    "repo:ukhsa-collaboration/devops-terraform-example-project:environment:${var.environment_name}",
    "repo:ukhsa-collaboration/devops-github-reusable-workflows:environment:${var.environment_name}",
    "repo:UKHSA-Internal/devops-terraform-example-project:environment:dev",
    "repo:UKHSA-Internal/devops-github-reusable-workflows:environment:dev"
  ]

  policies = {
    AdministratorAccess = "arn:aws:iam::aws:policy/AdministratorAccess"
  }
}

### The github-actions-app-deployer-oidc has more limited permissions than the github-actions-oidc role and is used
### to deploy applications. This will need to be adjusted for different projects, depending on what type of resources
### need to be deployed.
module "iam_app_deployer" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"
  version = "6.0.0"

  name            = "github-actions-app-deployer-oidc"
  use_name_prefix = false

  enable_github_oidc = true

  oidc_subjects = [
    "repo:ukhsa-collaboration/devops-hello-world-api:environment:${var.environment_name}",
    "repo:ukhsa-collaboration/devops-hello-world-frontend:environment:${var.environment_name}",
    "repo:ukhsa-collaboration/devops-hello-world-api:ref:refs/heads/main",
    "repo:ukhsa-collaboration/devops-hello-world-frontend:ref:refs/heads/main",
  ]

  policies = {
    AppDeployer = aws_iam_policy.app_deployer.arn
  }
}

resource "aws_iam_policy" "app_deployer" {
  name        = "github-actions-app-deployer"
  path        = "/"
  description = "Policy used by by the Github App Deployer IAM policy"

  policy = data.aws_iam_policy_document.app_deployer.json
}

data "aws_iam_policy_document" "app_deployer" {
  #checkov:skip=CKV_AWS_356:Allow App Deployer to deploy to ECS
  statement {
    sid = "AllowECSDeployments"
    actions = [
      "ecs:RunTask",
      "ecs:DeregisterContainerInstance",
      "ecs:RegisterTaskDefinition",
      "ecs:StartTask",
      "ecs:Describe*",
      "ecs:List*",
      "ecs:UpdateService"
    ]
    effect    = "Allow"
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"

      values = ["eu-west-2"]
    }
  }

  statement {
    sid = "AllowECRPush"
    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:BatchGetImage"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "AllowSSMUpdate"
    actions = [
      "ssm:PutParameter"
    ]
    effect    = "Allow"
    resources = ["*"]
  }

  version = "2012-10-17"
}
