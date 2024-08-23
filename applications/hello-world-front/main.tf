data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
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
    name   = "tag:Name"
    values = ["*-public-*"]
  }
}

data "aws_caller_identity" "current" {}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "v9.11.0"

  name    = "frontend-alb"
  vpc_id  = data.aws_vpc.main.id
  subnets = data.aws_subnets.public.ids

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = var.vpc_cidr_block
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"

      forward = {
        target_group_key = "frontend_tg"
      }
    }
  }

  target_groups = {
    frontend_tg = {
      name_prefix       = "front"
      protocol          = "HTTP"
      port              = 80
      target_type       = "ip"
      create_attachment = false
    }

  }
}

module "ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.11.2"

  name          = "hello-world-frontend"
  cluster_arn   = data.aws_ecs_cluster.main.arn
  desired_count = 1
  cpu           = 256
  memory        = 512

  service_connect_configuration = {
    namespace = "helloworld"
    service = {
      client_alias = {
        port     = 5000
        dns_name = "hello-world-frontend"
      }
      port_name      = "http"
      discovery_name = "hello-world-frontend"
    }
  }

  container_definitions = {
    app = {
      cpu       = 256
      memory    = 512
      essential = true
      image     = "${module.ecr.repository_url}:${var.image_tag}"
      port_mappings = [
        {
          name          = "http"
          containerPort = 5000
          hostPort      = 5000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "API_URL"
          value = "http://hello-world-api:8080"
        }
      ]


      readonly_root_filesystem = true

      log_configuration = {
        logDriver = "awslogs"
      }
      enable_cloudwatch_logging              = true
      create_cloudwatch_log_group            = true
      cloudwatch_log_group_name              = "/aws/ecs/hello-world-example/hello-world-front"
      cloudwatch_log_group_retention_in_days = 1

      memory_reservation = 100
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups.frontend_tg.arn
      container_name   = "app"
      container_port   = 5000
    }
  }

  security_group_rules = {
    alb_ingress_5000 = {
      type                     = "ingress"
      from_port                = 5000
      to_port                  = 5000
      protocol                 = "tcp"
      description              = "Ingress from frontend ALB"
      source_security_group_id = module.alb.security_group_id
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

module "ecr" {
  source  = "terraform-aws-modules/ecr/aws"
  version = "v2.2.1"

  repository_name = "hello-world-frontend"
  repository_type = "private"

  repository_read_write_access_arns = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
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