variable "image_tag" {
    description = "The tag of the image to deploy"
    type = string
    default = "latest"
}

variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block of the VPC that the project uses"
  type = string
}

variable "account_number" {
  description = "The AWS account number where the workload will run"
  type = string
}