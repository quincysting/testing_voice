# Admin Dashboard Module
# All configuration and secrets are managed externally and referenced from shared-config.tf
# This module only provisions infrastructure and references existing parameters/secrets

# Admin dashboard resources
resource "aws_security_group" "admin_dashboard_alb" {
  name        = "${var.app_name}-alb-sg"
  description = "Allow HTTP inbound traffic for admin dashboard"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = {
      http  = 80
      https = 443
    }

    content {
      protocol    = "tcp"
      from_port   = ingress.value
      to_port     = ingress.value
      cidr_blocks = ["0.0.0.0/0"] #[var.vpc_cidr_block] # Restrict to VPC CIDR block, to be refined once subnets information is available
      description = "Allow TCP ${ingress.value} from VPC CIDR"
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

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "admin_dashboard_tasks" {
  name        = "${var.app_name}-tasks-sg"
  description = "Allow inbound access from the ALB only for admin dashboard"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 4000
    to_port         = 4000
    security_groups = [aws_security_group.admin_dashboard_alb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-tasks-sg"
  }
}

resource "aws_lb" "admin_dashboard" {
  name               = trim(substr("${var.app_name}-alb", 0, 32), "-")
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.admin_dashboard_alb.id]
  subnets            = var.alb_subnets

  tags = {
    Name = "${var.app_name}-alb"
  }
}

resource "aws_lb_target_group" "admin_dashboard" {
  name        = trim(substr("${var.app_name}-tgt-grp", 0, 32), "-")
  port        = 4000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 30
    interval            = 60
    path                = "/"
    port                = "traffic-port"
    matcher             = "200-499"
  }

  tags = {
    Name = "${var.app_name}-target-group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "admin_dashboard" {
  load_balancer_arn = aws_lb.admin_dashboard.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.admin_dashboard.arn
  }
}

resource "aws_iam_role" "admin_dashboard_task_execution_role" {
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

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "admin_dashboard_execution_role_policy" {
  role       = aws_iam_role.admin_dashboard_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "admin_dashboard_secrets_access" {
  name        = "${var.app_name}-secrets-access"
  description = "Allow admin dashboard ECS tasks to access Secrets Manager"

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

resource "aws_iam_role_policy_attachment" "admin_dashboard_secrets_policy" {
  role       = aws_iam_role.admin_dashboard_task_execution_role.name
  policy_arn = aws_iam_policy.admin_dashboard_secrets_access.arn
}

resource "aws_iam_role" "admin_dashboard_task_role" {
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

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_ecs_task_definition" "admin_dashboard" {
  family                   = "${var.app_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = 2048
  memory                   = 2048
  execution_role_arn       = aws_iam_role.admin_dashboard_task_execution_role.arn
  task_role_arn            = aws_iam_role.admin_dashboard_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.app_name}"
      image     = "${var.repository_url}:${var.image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = 4000
          hostPort      = 4000
        }
      ]
      environment = [
        {
          name  = "PORT"
          value = "4000"
        }
      ]
      secrets = var.secrets
    }
  ])

  tags = {
    Name = "${var.app_name}-task-definition"
  }
}

resource "aws_ecs_service" "admin_dashboard" {
  name            = "${var.app_name}-service"
  cluster         = var.ecs_cluster
  task_definition = aws_ecs_task_definition.admin_dashboard.arn
  desired_count   = 1
  launch_type     = null

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider
    weight            = 100
    base              = 1
  }

  network_configuration {
    security_groups  = [aws_security_group.admin_dashboard_tasks.id]
    subnets          = var.alb_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.admin_dashboard.arn
    container_name   = var.app_name
    container_port   = 4000
  }

  lifecycle {
    ignore_changes = [
      task_definition # ← prevents roll‑backs
    ]
  }

  depends_on = [aws_lb_listener.admin_dashboard]

  tags = {
    Name = "${var.app_name}-service"
  }
}
