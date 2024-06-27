
module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "v5.8.1"

  cluster_name                          = var.ecs_cluster_name
  default_capacity_provider_use_fargate = true
}