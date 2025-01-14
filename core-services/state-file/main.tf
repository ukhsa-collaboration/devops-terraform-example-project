module "state_file" {
  source                  = "git::ssh://git@github.com/ukhsa-collaboration/devops-terraform-modules//terraform-modules/aws/state-file?ref=12028e3d7a05eab7526b8ef5746ae3c83a7ea020"
  iam_principals          = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-oidc"]
  state_bucket_kms_key_id = aws_kms_key.state_file.arn
  region_name             = data.aws_region.current.name
}

resource "aws_kms_key" "state_file" {
  description             = "Key used to encrypt both the state and logs buckets"
  enable_key_rotation     = true
  deletion_window_in_days = 14
}

resource "aws_kms_key_policy" "state_file" {
  key_id = aws_kms_key.state_file.id
  policy = jsonencode({
    Id = "Allow Github Actions user to use state file encryption key"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-oidc"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow Logs Service to use the key"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "kms:*"
        ]
        Resource = "*"
      }
    ]
    Version = "2012-10-17"
  })
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}