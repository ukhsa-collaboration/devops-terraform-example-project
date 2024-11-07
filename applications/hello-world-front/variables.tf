variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block of the VPC that the project uses"
  type        = string
}

variable "image_uri" {
  description = "The URI of Docker image to run without the tag. E.g. docker.io/postgres"
  type        = string
}