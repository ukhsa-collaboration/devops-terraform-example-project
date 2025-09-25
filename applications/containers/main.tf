########################################################################################################
# BEGIN SSM PARAMETERS
########################################################################################################
# Why:
# We store the container image tag in SSM Parameter Store so the application
# delivery pipeline can update it per deploy without changing Terraform code.
# Terraform reads the current value via a data source, and `lifecycle { ignore_changes = [value] }`
# prevents Terraform from trying to revert pipeline-driven updates (avoids config drift).

# What this does:
# - Creates a non-sensitive String parameter at /helloworld/[name of service]/image_tag.
# - Marks changes to the parameter's value as ignored by Terraform state to keep deploys fast and drift-free.
# - Reads the live value with `data.aws_ssm_parameter.image_tag` and composes the image reference:
#     image = "${var.image_uri}:${data.aws_ssm_parameter.image_tag.value}"

# Security & ops notes:
# - Parameter is non-sensitive (just an image tag), hence the Checkov skip.
# - Use IAM to restrict who can PutParameter on this key (pipeline only).
# - SSM gives history/audit, enabling easy rollbacks or promotions across environments.

resource "aws_ssm_parameter" "frontend_image_tag" {
  #checkov:skip=CKV_AWS_337:The image tag is not considered sensitive
  name  = "/helloworld/frontend/image_tag"
  type  = "String"
  value = "latest"

  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_ssm_parameter" "frontend_image_tag" {
  name = aws_ssm_parameter.frontend_image_tag.name
}

resource "aws_ssm_parameter" "backend_image_tag" {
  #checkov:skip=CKV_AWS_337:The image tag is not considered sensitive
  name  = "/helloworld/backend/image_tag"
  type  = "String"
  value = "latest"

  lifecycle {
    ignore_changes = [value]
  }
}

data "aws_ssm_parameter" "backend_image_tag" {
  name = aws_ssm_parameter.frontend_image_tag.name
}
########################################################################################################
# END SSM PARAMETERS
########################################################################################################

########################################################################################################
# BEGIN APPLICATION LOAD BALANCER
########################################################################################################
# Why:
# Expose the ECS service to the internet via a public, managed entry point that can route
# HTTP(S) traffic to containers running in private subnets.

# What this does:
# - Provisions an internet-facing Application Load Balancer in public subnets.
# - Opens SG ingress for ports 80/443 from anywhere; forwards HTTP:80 to the target group.
# - Creates a target group for the frontend service (IP targets on port 5000). The ECS service
#   will attach tasks to this target group (attachment managed inside of the ECS module call).

# Security & ops notes:
# - Consider enabling HTTPS with an ACM certificate and redirecting HTTP->HTTPS to encrypt traffic.
# - Restrict ingress CIDRs if possible; 0.0.0.0/0 is open to the world by design.
# - Keep egress limited to the VPC CIDR (already set) to reduce lateral exposure.
# - Consider enabling deletion protection and access logs (S3) for auditability.
# - Optionally front the ALB with AWS WAF to mitigate common web threats.
# - Tune target group health checks (path, interval, thresholds) to match the app’s readiness.

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "v10.0.0"

  name    = "aw-hw-euw2-${var.environment_name}-alb-public"
  vpc_id  = data.aws_vpc.main.id
  subnets = data.aws_subnets.public.ids

  enable_deletion_protection = false
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
      port              = 5000
      target_type       = "ip"
      create_attachment = false
    }

  }
}

########################################################################################################
# END APPLICATION LOAD BALANCER
########################################################################################################

########################################################################################################
# BEGIN ECS SERVICES
########################################################################################################
# Why:
# Run the frontend workload on ECS Fargate with a managed deployment model, autoscaling windows,
# and integration to the public ALB.

# What this does:
# - Defines a service + task definition (CPU/memory, ports, env) for the frontend and backend containers.
# - Attaches the services to the ALB target group.
# - Enables CloudWatch Logs and sets a short retention for lower environments.
# - Applies scheduled scale-down/restore windows via `autoscaling_scheduled_actions`.

# Security & ops notes:
# - Service has no public IP; ingress flows only from the ALB SG. Tasks run in private subnets.
# - SG egress is open (0.0.0.0/0, tcp) — tighten if you know exact egress needs (DB, APIs).
# - `readonly_root_filesystem = true` hardens the container; keep writing to ephemeral/task volumes only.
# This may not be possible with all containers and Fargate does not make it easy to use tmpfs as an alternative. 
# See https://github.com/aws/containers-roadmap/issues/736
# - Ensure task/execution IAM roles are least-privilege.
# - Consider health check settings on the target group and container to match app readiness.
# - Image is parameterized (`${var.image_uri}:${data.aws_ssm_parameter.frontend_image_tag.value}`) so
#   CI/CD can update the tag without Terraform drift. See SSM Parameters comment for more info on this.

moved {
  from = module.ecs_service
  to   = module.frontend_ecs_service
}

module "frontend_ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "6.4.0"

  name          = "aw-hello-world-euw2-${var.environment_name}-ecssvc-frontend"
  cluster_arn   = data.aws_ecs_cluster.main.arn
  desired_count = 1
  cpu           = 256
  memory        = 512

  autoscaling_scheduled_actions = var.scheduled_scaledown ? local.scheduled_scaledown_policy : {}


  tasks_iam_role_name            = "aw-hello-world-global-${var.environment_name}-iamrole-task-frontend"
  tasks_iam_role_use_name_prefix = false

  task_exec_iam_role_name            = "aw-hello-world-global-${var.environment_name}-iamrole-taskexec-frontend"
  task_exec_iam_role_use_name_prefix = false


  container_definitions = {
    app = {
      cpu       = 256
      memory    = 512
      essential = true
      image     = "${var.frontend_image_uri}:${data.aws_ssm_parameter.frontend_image_tag.value}"
      portMappings = [
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


      readonlyRootFilesystem = true

      logConfiguration = {
        logDriver = "awslogs"
      }
      enable_cloudwatch_logging              = true
      create_cloudwatch_log_group            = true
      cloudwatch_log_group_name              = "/aws/ecs/hello-world-example/hello-world-front"
      cloudwatch_log_group_retention_in_days = 1

      memoryReservation = 100
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups.frontend_tg.arn
      container_name   = "app"
      container_port   = 5000
    }
  }

  security_group_ingress_rules = {
    alb_5000 = {
      from_port                    = 5000
      to_port                      = 5000
      ip_protocol                  = "tcp"
      description                  = "Ingress from ALB"
      referenced_security_group_id = module.alb.security_group_id
    }
  }
  security_group_egress_rules = {
    all = {
      from_port   = 0
      to_port     = 65535
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  assign_public_ip = false
  subnet_ids       = data.aws_subnets.private.ids
}

module "backend_ecs_service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "6.4.0"

  name          = "aw-hello-world-euw2-${var.environment_name}-ecssvc-backend"
  cluster_arn   = data.aws_ecs_cluster.main.arn
  desired_count = 1
  cpu           = 256
  memory        = 512

  autoscaling_scheduled_actions = var.scheduled_scaledown ? local.scheduled_scaledown_policy : {}

  tasks_iam_role_name            = "aw-hello-world-global-${var.environment_name}-iamrole-task-backend"
  tasks_iam_role_use_name_prefix = false

  task_exec_iam_role_name            = "aw-hello-world-global-${var.environment_name}-iamrole-taskexec-backend"
  task_exec_iam_role_use_name_prefix = false

  container_definitions = {
    app = {
      cpu       = 256
      memory    = 512
      essential = true
      image     = "${var.backend_image_uri}:${data.aws_ssm_parameter.backend_image_tag.value}"

      portMappings = [
        {
          name          = "http"
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      readonlyRootFilesystem = true

      logConfiguration = {
        logDriver = "awslogs"
      }
      enable_cloudwatch_logging              = true
      create_cloudwatch_log_group            = true
      cloudwatch_log_group_name              = "/aws/ecs/hello-world-example/hello-world-backend"
      cloudwatch_log_group_retention_in_days = 1

      memoryReservation = 100
    }
  }

  security_group_ingress_rules = {
    alb_8080 = {
      from_port                    = 8000
      to_port                      = 8000
      ip_protocol                  = "tcp"
      description                  = "Ingress from ALB"
      referenced_security_group_id = module.alb.security_group_id
    }
  }
  security_group_egress_rules = {
    all = {
      from_port   = 0
      to_port     = 65535
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  assign_public_ip = false
  subnet_ids       = data.aws_subnets.private.ids
}

########################################################################################################
# BEGIN PASSROLE DEPLOYER PERMISSIONS
########################################################################################################

# Why:
# ECS tasks and services assume two roles (task role and execution role). The caller that creates/updates
# those tasks/services must have iam:PassRole on those specific roles; otherwise deployments will fail
# with AccessDenied errors.
#
# What it does:
# Permission for the GitHub Actions deployer IAM role to pass only the ECS task and execution roles
# defined in this module, enabling it to create/update the related ECS services.
#
# Security & ops notes:
# Scope is tightly limited to the exact role ARNs (no wildcards) to enforce least privilege and
# reduce the risk of privilege escalation via overly broad iam:PassRole permissions.

data "aws_iam_role" "deployer" {
  name = "github-actions-app-deployer-oidc"
}

resource "aws_iam_policy" "deployer" {
  name        = "aw-hello-world-euw2-${var.environment_name}-iampolicy-task-passrole"
  description = "Policy to allow GitHub Actions to PassRole for frontend and backend ECS roles"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "PassRole",
        Effect = "Allow",
        Action = [
          "iam:PassRole"
        ],
        Resource = [
          module.frontend_ecs_service.tasks_iam_role_arn,
          module.frontend_ecs_service.task_exec_iam_role_arn,
          module.backend_ecs_service.tasks_iam_role_arn,
          module.backend_ecs_service.task_exec_iam_role_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "deployer" {
  role       = data.aws_iam_role.deployer.name
  policy_arn = aws_iam_policy.deployer.arn
}

########################################################################################################
# END PASSROLE DEPLOYER PERMISSIONS
########################################################################################################
