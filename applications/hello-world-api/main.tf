data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
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
    name   = "tag:Name"
    values = ["*-public-*"]
  }
}

module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.11.2"

  name          = "hello-world-api"
  cluster_arn   = data.aws_ecs_cluster.main.arn
  desired_count = 1
  cpu           = 256
  memory        = 256

  container_definitions = {
    app = {
      cpu       = 256
      memory    = 256
      essential = true
      image     = "${module.ecr.repository_url}:${var.image_tag}"
      port_mappings = [
        {
          name          = "http"
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "MEMCACHED_HOST"
          value = data.aws_elasticache_cluster.memcached.cluster_address
        },
        {
          name  = "MEMCACHED_PORT"
          value = tostring(data.aws_elasticache_cluster.memcached.port)
        }
      ]

      readonly_root_filesystem = true

      enable_cloudwatch_logging = false
      memory_reservation        = 100
    }
  }

  subnet_ids = data.aws_subnets.public.ids
}

module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "v2.2.1"

  repository_name = "hello-world-api"
  repository_type = "private"

  repository_read_write_access_arns = ["arn:aws:iam::${var.account_number}:root"]
  create_lifecycle_policy           = true
  repository_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Keep last image",
        selection = {
          tagStatus     = "tagged",
          tagPrefixList = ["v"],
          countType     = "imageCountMoreThan",
          countNumber   = 1
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}

