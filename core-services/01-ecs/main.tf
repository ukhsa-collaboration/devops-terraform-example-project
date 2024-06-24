module "ecs_cluster" {
  source = "terraform-aws-modules/ecs/aws//modules/cluster"

  cluster_name = var.ecs_cluster_name
}

// TODO: Remove all of the below when moving the above to Fargate
resource "aws_key_pair" "ec2_key" {
    key_name   = "ec2_key"
    public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB7YX+nyFbclLm52WfPj84ziw7Xmm9sjYzmMcUzuInac Sam"
}


resource "aws_iam_instance_profile" "ecs_instance_profile" {
  name = "ecsEC2InstanceProfile"
  role = aws_iam_role.ecs_instance_role.name
}

resource "aws_instance" "ecs_instance" {
  ami                    = var.compute_ami_id
  instance_type          = var.compute_instance_type
  iam_instance_profile   = aws_iam_instance_profile.ecs_instance_profile.name
  key_name               = aws_key_pair.ec2_key.key_name
  vpc_security_group_ids = [aws_security_group.ecs_sg.id]
  subnet_id              = data.aws_subnets.public.ids[0]
  associate_public_ip_address = true

  user_data = base64encode(<<-EOF
              #!/bin/bash
              echo ECS_CLUSTER=${module.ecs_cluster.name} >> /etc/ecs/ecs.config
              EOF
  )

  tags = {
    Name = "ecs-instance"
  }
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "ecsInstanceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_security_group" "ecs_sg" {
  vpc_id = data.aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 5000
    to_port   = 5000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8080
    to_port   = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
