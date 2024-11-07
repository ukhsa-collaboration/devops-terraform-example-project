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

resource "aws_ssm_parameter" "image_tag" {
  #checkov:skip=CKV_AWS_337:The image tag is not considered sensitive
  name  = "/helloworld/api/image_tag"
  type  = "String"
  value = "latest"

  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_ssm_parameter" "image_tag" {
  name = aws_ssm_parameter.image_tag.name
}

module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.11.4"

  name          = "hello-world-api"
  cluster_arn   = data.aws_ecs_cluster.main.arn
  desired_count = 1
  cpu           = 256
  memory        = 512

  service_connect_configuration = {
    namespace = "helloworld"
    service = {
      client_alias = {
        port     = 8080
        dns_name = "hello-world-api"
      }
      port_name      = "http"
      discovery_name = "hello-world-api"
    }
  }

  container_definitions = {
    app = {
      cpu       = 256
      memory    = 512
      essential = true
      image     = "${var.image_uri}:${data.aws_ssm_parameter.image_tag.value}"

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

      log_configuration = {
        logDriver = "awslogs"
      }
      enable_cloudwatch_logging              = true
      create_cloudwatch_log_group            = true
      cloudwatch_log_group_name              = "/aws/ecs/hello-world-example/hello-world-api"
      cloudwatch_log_group_retention_in_days = 1

      memory_reservation = 100
    }
  }

  security_group_rules = {
    ingress_vpc = {
      type        = "ingress"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "Ingress from VPC"
      cidr_blocks = [var.vpc_cidr_block]
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  assign_public_ip = true
  subnet_ids       = data.aws_subnets.public.ids
}