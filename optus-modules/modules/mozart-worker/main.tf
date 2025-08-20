
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

resource "aws_security_group" "ecs_tasks" {
  name        = "${var.app_name}-ecs-tasks-sg"
  description = "Allow inbound access from the ALB only"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = var.container_port
    to_port         = var.container_port
    security_groups = [aws_security_group.alb.id]
  }

  # Allow inbound TCP for imap-server port from public for NLB access
  # TODO: Tighten this to specific VPC CIDRs or NLB source IPs if possible/needed instead of 0.0.0.0/0
  ingress {
    protocol    = "tcp"
    from_port   = var.voicemail_container_port
    to_port     = var.voicemail_container_port
    cidr_blocks = [var.vpc_cidr_block] # Restrict to VPC CIDR block, to be refined once subnets information is available
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
    for_each = toset([80, 443])
    content {
      protocol    = "tcp"
      from_port   = ingress.value
      to_port     = ingress.value
      cidr_blocks = [var.vpc_cidr_block] # Restrict to VPC CIDR block, to be refined once subnets information is available
      description = "Allow TCP port ${ingress.value} from VPC"
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

resource "aws_autoscaling_group" "ecs" {
  name                 = "${var.app_name}-ecs-asg"
  vpc_zone_identifier  = var.worker_subnets
  launch_configuration = aws_launch_configuration.ecs.name
  min_size             = 1
  max_size             = 8
  desired_capacity     = 1

  tag {
    key                 = "Name"
    value               = "${var.app_name}-ecs-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
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


resource "aws_launch_configuration" "ecs" {
  name_prefix          = "${var.app_name}-ecs-"
  image_id             = data.aws_ami.ecs_optimized.id
  instance_type        = "t3.medium"
  security_groups      = [aws_security_group.instance.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  key_name             = null
  user_data            = <<-EOF
                          #!/bin/bash
                          echo ECS_CLUSTER=${var.ecs_cluster} >> /etc/ecs/ecs.config
                          EOF

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_ecs_task_definition" "mozart_worker" {
  family                   = "${var.app_name}-mozart-worker-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.app_name}-mozart-worker"
      image     = "${var.repository_url}" #:${var.image_tag}"
      essential = true
      command   = ["queues"]
      portMappings = [
        {
          containerPort = var.voicemail_container_port,
          protocol      = "tcp"
          # hostPort      = var.voicemail_container_port
        }
      ]
      environment = concat(var.environment_variables, [
        {
          name  = "SWIFT_BACKTRACE"
          value = "enable=yes"
        }
      ])
      secrets = var.secrets

    }
  ])

  tags = {
    Name = "${var.app_name}-mozart-worker-task-definition"
  }
}

resource "aws_security_group" "instance" {
  name        = "${var.app_name}-instance-sg"
  description = "Security group for EC2 instances in ECS cluster"
  vpc_id      = var.vpc_id




  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"] # to be refined once subnets information is available
  }

  dynamic "ingress" {
    for_each = [
      { protocol = "tcp", port = 22 },
      { protocol = "tcp", port = 55060 },
      { protocol = "udp", port = 55060 },
      { protocol = "udp", port = 6060 }
    ]
    content {
      protocol    = ingress.value.protocol
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      cidr_blocks = [var.vpc_cidr_block] # Restrict to VPC CIDR block, to be refined once subnets information is available
      description = "Allow ${ingress.value.protocol} ${ingress.value.port}"
    }
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-instance-sg"
  }
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

resource "aws_iam_role_policy_attachment" "ec2_instance_role_policy" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Add a custom policy for additional EC2 permissions
resource "aws_iam_role_policy" "ec2_instance_additional_policy" {
  name = "${var.app_name}-ec2-additional-policy"
  role = aws_iam_role.ec2_instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
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

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.app_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}


resource "aws_ecs_capacity_provider" "ec2" {
  name = "${var.app_name}-ec2-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs.arn

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "worker_capacity_providers" {
  cluster_name = var.ecs_cluster

  # Worker module only manages its own capacity provider
  capacity_providers = [var.imap_ec2_capacity_provider_name, var.kamailio_ec2_capacity_provider_name, var.voicemail_ec2_capacity_provider_name, aws_ecs_capacity_provider.ec2.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ec2.name
  }
  lifecycle {
    ignore_changes = [capacity_providers, default_capacity_provider_strategy]
  }
}

resource "aws_ecs_service" "mozart_worker" {
  name            = "${var.app_name}-service"
  cluster         = var.ecs_cluster
  task_definition = aws_ecs_task_definition.mozart_worker.arn
  desired_count   = var.desired_count
  launch_type     = null

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ec2.name
    weight            = 100
    base              = 1
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = var.worker_subnets
    assign_public_ip = false
  }

  lifecycle {
    ignore_changes = [
      task_definition
    ]
  }

  depends_on = [aws_ecs_task_definition.mozart_worker, aws_ecs_cluster_capacity_providers.worker_capacity_providers]

  tags = {
    Name = "${var.app_name}-service"
  }
}

resource "aws_iam_policy" "worker_secrets_access" {
  name        = "${var.app_name}-secrets-access"
  description = "Allow voicemail server ECS tasks to access Secrets Manager"

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

resource "aws_iam_role_policy_attachment" "task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "task_execution_secrets_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.worker_secrets_access.arn
}

resource "aws_iam_role_policy_attachment" "task_role_secrets_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.worker_secrets_access.arn
}


resource "aws_lb_target_group" "voicemail" {
  name        = trim(substr("${var.app_name}-tgt-grp", 0, 32), "-")
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 30
    interval            = 60
    # command             = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
    path    = "/health"
    port    = 8080
    matcher = "200-299"
  }

  tags = {
    Name = "${var.app_name}-target-group"
  }

  lifecycle {
    create_before_destroy = true
  }
}