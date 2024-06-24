terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.52.0"
    }
  }

  # This is intentionally left blank and is populated using CLI flags as part of the CI pipeline
  backend "s3" {}
}
