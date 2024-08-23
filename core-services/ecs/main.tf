
module "ecs_cluster" {
  source  = "terraform-aws-modules/ecs/aws//modules/cluster"
  version = "v5.11.4"

  cluster_name                          = var.ecs_cluster_name
  default_capacity_provider_use_fargate = true

  cluster_service_connect_defaults = {
    namespace = aws_service_discovery_http_namespace.helloworld.arn
  }
}

resource "aws_service_discovery_http_namespace" "helloworld" {
  name        = "helloworld"
  description = "example"
}