variable "vpc_cidr_block" {
  description = "The CIDR block to be used for the VPC"
  type        = string
}

variable "environment_name" {
  description = "The name of the environment. Used to create the OIDC permissions"
  type        = string
}
