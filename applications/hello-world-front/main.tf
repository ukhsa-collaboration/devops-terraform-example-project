module "alb" {
  source = "terraform-aws-modules/alb/aws"

  version = "v9.9.0"
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
      port            = 80
      protocol        = "HTTP"

      forward = {
        target_group_key = "frontend_tg"
      }
    }
  }

  target_groups = {
    frontend_tg = {
      name_prefix      = "front"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
      create_attachment = false
    }
    
  }
}

module "ecs_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = "hello-world-frontend"
  cluster_arn = data.aws_ecs_cluster.main.arn
  launch_type = "EC2"
  network_mode = "bridge"
  requires_compatibilities = ["EC2"]
  desired_count = 1
  cpu    = 256
  memory = 256

  container_definitions = {
    app = {
      cpu       = 256
      memory    = 256
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
        # We'd use something better than this really, using the external address is simpler for
        # demo purposes.
        name  = "API_URL"
        value = "http://${data.aws_instance.ecs_instance.public_ip}:8080"
        }
      ]


      readonly_root_filesystem = true

      enable_cloudwatch_logging = false
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

  subnet_ids = data.aws_subnets.public.ids
}

module "ecr" {
  source = "terraform-aws-modules/ecr/aws"

  repository_name = "hello-world-frontend"
  repository_type = "private"

  repository_read_write_access_arns = ["arn:aws:iam::${var.account_number}:root"]
  create_lifecycle_policy = true
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