variable "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block of the VPC that the project uses"
  type        = string
}

variable "frontend_image_uri" {
  description = "The URI of Docker image to run without the tag. E.g. docker.io/postgres"
  type        = string
}

variable "backend_image_uri" {
  description = "The URI of Docker image to run without the tag. E.g. docker.io/postgres"
  type        = string
}


variable "autoscaling_min_capacity" {
  description = "The minimum amount of containers to run at any one time"
  type        = number
  default     = 3
}

variable "autoscaling_max_capacity" {
  description = "The maximum amount of containers to run at any one time"
  type        = number
  default     = 10
}

variable "scheduled_scaledown" {
  description = "If true, the service will scale down in the evenings and on weekends to prevent unnecessary cost"
  type        = bool
  default     = false
}

variable "environment_name" {
  description = "The name of the environment"
  type        = string
}