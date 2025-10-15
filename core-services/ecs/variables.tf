variable "ecs_cluster_name" {
  description = "The name of the ECS cluster to be creatd"
  type        = string
}

variable "environment_name" {
  description = "The name of the environment. Used to create the OIDC permissions"
  type        = string
}
