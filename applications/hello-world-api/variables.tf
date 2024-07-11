variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "image_tag" {
  description = "The tag of the image to deploy"
  type        = string
  default     = "latest"
}

variable "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  type        = string
}