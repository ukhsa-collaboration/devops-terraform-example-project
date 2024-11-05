module "iam_github_oidc_provider" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-provider"
  version = "5.47.1"
}

module "iam_github_oidc_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-github-oidc-role"
  version = "5.47.1"

  name = "github-actions-oidc"

  subjects = [
    "ukhsa-collaboration/devops-terraform-example-project:environment:${var.environment_name}",
    "ukhsa-collaboration/devops-github-reusable-workflows:environment:${var.environment_name}",
  ]

  policies = {
    CIUser = aws_iam_policy.ci_user.arn
  }
}

resource "aws_iam_policy" "ci_user" {
  name = "github-actions-oidc"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:*",
          "ecr:*",
          "s3:*",
          "servicediscovery:*",
          "application-autoscaling:*",
          "logs:*",
          "elasticache:*",
          "elasticloadbalancing:*",
          "ecs:*",
          "ec2:*"
        ],
        "Resource" : [
          "*"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:RequestedRegion" : ["eu-west-2"]
          }
        }
      }
    ]
  })
}