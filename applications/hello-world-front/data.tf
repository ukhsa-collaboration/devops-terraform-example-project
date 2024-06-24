data "aws_vpc" "main" {
  filter {
    name = "tag:Name"
    values = ["main"]
  }
}

data "aws_ecs_cluster" "main" {
  cluster_name = var.ecs_cluster_name
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

data "aws_instance" "ecs_instance" {
  filter {
    name   = "image-id"
    values = ["ami-05d6c5e5d6fc4f650"]
  }
}