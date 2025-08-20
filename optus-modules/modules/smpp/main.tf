# SMPP Server Module
# All configuration and secrets are managed externally and referenced from shared-config.tf
# This module only provisions infrastructure and references existing parameters/secrets

# Database secrets are now provided through shared configuration
# Applications receive SUBSCRIBER_DB_PASSWORD and KAM_DB_PASSWORD as environment variables


resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.app_name}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_iam_role" "ecs_task_role" {
  name = "${var.app_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_role_secrets_manager_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.secrets_manager_access.arn
}


#--- SMPP Server Resources ---

resource "aws_ecs_task_definition" "smpp_server" {
  family                   = "${var.app_name}-server-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.cpu    # Using general CPU/memory, adjust if needed
  memory                   = var.memory # Using general CPU/memory, adjust if needed
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn # Assuming same task role is sufficient

  container_definitions = jsonencode([
    {
      name      = "${var.app_name}-server"
      image     = "${var.repository_url}:${var.image_tag}" # Assumes same image as mozart/worker
      essential = true
      portMappings = [
        {
          containerPort = var.smpp_server_container_port
          # hostPort is not needed for awsvpc with NLB using IP targets
        }
      ]
      environment = var.environment_variables
      secrets     = var.secrets

    }
  ])

  tags = {
    Name = "${var.app_name}-server-task-definition"
  }
}


resource "aws_lb" "smpp_nlb" {
  name               = "${var.app_name}-nlb"
  internal           = true
  load_balancer_type = "application"               #"network"
  subnets            = var.alb_subnets             # NLB needs to be in public subnets to be internet-facing
  security_groups    = [aws_security_group.alb.id] # Add security group for ALB

  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.app_name}-nlb"
  }
}

resource "aws_lb_target_group" "smpp_server" {
  name        = "${var.app_name}-tgt-grp"
  port        = var.smpp_server_container_port
  protocol    = "HTTP" #"TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    protocol            = "HTTP" #"TCP" # Basic TCP health check
    port                = tostring(var.smpp_server_container_port)
    path                = "/health"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = {
    Name = "${var.app_name}-server-tg"
  }
}

resource "aws_lb_listener" "smpp_server" {
  load_balancer_arn = aws_lb.smpp_nlb.arn
  port              = "80" # Listen on port 80 instead of 8144
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.smpp_server.arn
  }
}

resource "aws_ecs_service" "smpp_server" {
  name            = "${var.app_name}-server-service"
  cluster         = var.ecs_cluster
  task_definition = aws_ecs_task_definition.smpp_server.arn
  desired_count   = var.smpp_server_desired_count
  #launch_type     = null # Using capacity provider

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider_for_smpp
    weight            = 100
    base              = 1
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id] # Reuses existing SG, added rule for smpp port
    subnets          = var.imap_subnets                       # Private subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.smpp_server.arn
    container_name   = "${var.app_name}-server"
    container_port   = var.smpp_server_container_port
  }

  depends_on = [aws_lb_listener.smpp_server, aws_ecs_task_definition.smpp_server]

  tags = {
    Name = "${var.app_name}-server-service"
  }
}



# resource "aws_ecs_capacity_provider" "ec2" {
#   name = "${var.app_name}-ec2-capacity-provider"

#   auto_scaling_group_provider {
#     auto_scaling_group_arn = aws_autoscaling_group.ecs.arn

#     managed_scaling {
#       maximum_scaling_step_size = 1000
#       minimum_scaling_step_size = 1
#       status                    = "ENABLED"
#       target_capacity           = 100
#     }
#   }
# }

# resource "aws_ecs_cluster_capacity_providers" "smpp_capacity_providers" {
#   cluster_name = var.ecs_cluster

#   # Add SMPP capacity provider to cluster (other modules will manage their own)
#   #capacity_providers = [aws_ecs_capacity_provider.ec2.name]
#   capacity_providers = ["kamailio-lab-ec2-capacity-provider", "imap-lab-1-ec2-capacity-provider", "kamailio-sbc-lab-ec2-capacity-provider", "mozart-vmail-lab-ec2-capacity-provider", "mozart-worker-lab-worker-capacity-provider", aws_ecs_capacity_provider.ec2.name]

#   default_capacity_provider_strategy {
#     base              = 1
#     weight            = 100
#     capacity_provider = var.capacity_provider_for_smpp
#   }

#   lifecycle {
#     ignore_changes = [capacity_providers, default_capacity_provider_strategy]
#   }
# }


# resource "aws_autoscaling_group" "ecs" {
#   name                = "${var.app_name}-ecs-asg"
#   vpc_zone_identifier = var.subnets
#   #   launch_configuration = aws_launch_template.ecs.name
#   min_size         = 1
#   max_size         = 8
#   desired_capacity = 2

#   launch_template {
#     id      = aws_launch_template.ecs.id
#     version = "$Latest"
#   }

#   tag {
#     key                 = "Name"
#     value               = "${var.app_name}-ecs-instance"
#     propagate_at_launch = true
#   }

#   tag {
#     key                 = "AmazonECSManaged"
#     value               = ""
#     propagate_at_launch = true
#   }

#   tag {
#     key                 = "CapacityProvider"
#     value               = "${var.app_name}-ec2-capacity-provider"
#     propagate_at_launch = true
#   }
# }


# resource "aws_launch_template" "ecs" {
#   name_prefix   = "${var.app_name}-ecs-lt"
#   image_id      = var.ecs_ami_id
#   instance_type = var.instance_type
#   #   key_name      = var.key_name

#   iam_instance_profile {
#     name = aws_iam_instance_profile.ec2_instance_profile.name
#   }

#   user_data = base64encode(<<-EOF
#               #!/bin/bash
#               echo ECS_CLUSTER=${var.ecs_cluster} >> /etc/ecs/ecs.config
#               EOF
#   )

#   network_interfaces {
#     associate_public_ip_address = true
#     security_groups             = [aws_security_group.instance.id]
#   }
# }

# resource "aws_launch_configuration" "ecs" {
#   name_prefix          = "${var.app_name}-ecs-"
#   image_id             = data.aws_ami.ecs_optimized.id
#   instance_type        = "t3.medium"
#   security_groups      = [aws_security_group.instance.id]
#   iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
#   key_name             = null
#   user_data            = base64encode(<<-EOF
#               #!/bin/bash
#               echo ECS_CLUSTER=${var.ecs_cluster} >> /etc/ecs/ecs.config
#               EOF
#   )

#   lifecycle {
#     create_before_destroy = true
#   }
# }

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.app_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role" "ec2_instance_role" {
  name = "${var.app_name}-ec2-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.app_name}-ecs-tasks-sg"
  description = "Allow inbound access from the ALB only"
  vpc_id      = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = var.container_port
    to_port     = var.container_port
    cidr_blocks = [var.lb_subnet1_cidr_block, var.lb_subnet2_cidr_block] # Allow access from ALB and public subnets
  }

  ingress {
    protocol        = "tcp"
    from_port       = var.container_port
    to_port         = var.container_port
    security_groups = [aws_security_group.instance.id]
  }

  # Allow inbound TCP for smpp-server port from VPC for NLB access
  ingress {
    protocol    = "tcp"
    from_port   = var.smpp_server_container_port # 1775
    to_port     = var.smpp_server_container_port # 1775
    cidr_blocks = ["0.0.0.0/0"]                  # to be updated after receiving subnets information ["10.0.0.0/16"]  # Allow from VPC for NLB health checks
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-ecs-tasks-sg"
  }
}

resource "aws_security_group" "alb" {
  name        = "${var.app_name}-alb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = {
      http  = 80
      https = 443
      smpp1 = 1775
      smpp2 = 8144
    }

    content {
      protocol    = "tcp"
      from_port   = ingress.value
      to_port     = ingress.value
      cidr_blocks = ["0.0.0.0/0"] # to be updated after receiving subnets information
    }
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-alb-sg"
  }
}

# resource "aws_security_group_rule" "allow_from_instance_to_tasks" {
#   type                     = "ingress"
#   from_port                = var.smpp_server_container_port
#   to_port                  = var.smpp_server_container_port
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.ecs_tasks.id
#   source_security_group_id = aws_security_group.instance.id
# }

resource "aws_security_group" "instance" {
  name        = "${var.app_name}-instance-sg"
  description = "Security group for EC2 instances in ECS cluster"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = {
      ssh_tcp     = { protocol = "tcp", port = 22 }
      app_tcp     = { protocol = "tcp", port = 55060 }
      app_udp     = { protocol = "udp", port = 55060 }
      control_udp = { protocol = "udp", port = 6060 }
    }

    content {
      protocol    = ingress.value.protocol
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      cidr_blocks = ["0.0.0.0/0"] # to be updated after receiving subnets information
    }
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  #   egress {
  #   protocol        = "tcp"
  #   from_port       = var.container_port
  #   to_port         = var.container_port
  #   security_groups = [aws_security_group.ecs_tasks.id]
  #   description     = "Allow EC2 to reach ECS tasks"
  # }

  tags = {
    Name = "${var.app_name}-instance-sg"
  }
}


# Add permissions for Secrets Manager
resource "aws_iam_policy" "secrets_manager_access" {
  name        = "${var.app_name}-secrets-manager-access"
  description = "Allow ECS tasks to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "ssm:GetParameters",
          "ssm:GetParameter",
          "ssm:DescribeParameters"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_secrets_manager_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.secrets_manager_access.arn
}

data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- End SMPP Server Resources --- 