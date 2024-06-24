data "aws_vpc" "main" {
  filter {
    name = "tag:Name"
    values = ["main"]
  }
}

data "aws_ecs_cluster" "main" {
  cluster_name = var.ecs_cluster_name
}

data "aws_elasticache_cluster" "memcached" {
    cluster_id = "memcached-cluster"
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name = "tag:Name"
    values = ["*-public-*"]
  }
}
