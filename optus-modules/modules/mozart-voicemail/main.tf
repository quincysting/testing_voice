# Mozart Voicemail server resources


data "aws_launch_template" "existing" {
  filter {
    name   = "tag:Name"
    values = ["mozart-${var.environment}-launch_template"]
  }
}

# Mozart Voicemail Module
# All configuration and secrets are managed externally and referenced from shared-config.tf
# This module only provisions infrastructure and references existing parameters/secrets

# Database secrets are now provided through shared configuration
# Applications receive SUBSCRIBER_DB_PASSWORD and KAM_DB_PASSWORD as environment variables

resource "aws_autoscaling_group" "ecs-lab-voicemail" {
  name                = "${var.app_name}-asg"
  vpc_zone_identifier = var.voicemail_admin_dashboard_subnets
  # launch_template = data.aws_launch_template.existing.id
  min_size         = 1
  max_size         = 2
  desired_capacity = 1

  launch_template {
    id      = data.aws_launch_template.existing.id
    version = "$Latest"
  }

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
  depends_on = [data.aws_launch_template.existing]
  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

resource "aws_ecs_capacity_provider" "ec2" {
  name = "${var.app_name}-ec2-capacity-provider" # "voicemail-lab-ec2-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs-lab-voicemail.arn

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }

  #depends_on = [aws_autoscaling_group.ecs-lab-voicemail]
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = var.ecs_cluster

  #capacity_providers = [var.kamailio_ec2_capacity_provider_name, var.voicemail_ec2_capacity_provider_name, var.imap_ec2_capacity_provider_name, aws_ecs_capacity_provider.ec2.name]
  capacity_providers = [var.kamailio_ec2_capacity_provider_name, aws_ecs_capacity_provider.ec2.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ec2.name
  }
  lifecycle {
    ignore_changes = [capacity_providers, default_capacity_provider_strategy]
  }
  depends_on = [
    #aws_autoscaling_group.ecs-lab-voicemail,
    #aws_ecs_service.voicemail,
    aws_ecs_capacity_provider.ec2
  ]
}

resource "aws_iam_policy" "voicemail_secrets_access" {
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

resource "aws_security_group" "voicemail_alb" {
  name        = "${var.app_name}-alb-sg"
  description = "Allow HTTP/HTTPS inbound traffic "
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

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "voicemail" {
  name               = "${var.app_name}-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.voicemail_alb.id]
  subnets            = var.alb_subnets

  tags = {
    Name = "${var.app_name}-alb"
  }
  #depends_on = [aws_security_group.voicemail_alb]
}

resource "aws_security_group" "voicemail" {
  name        = "${var.app_name}-sg"
  description = "Allow inbound access from the ALB only to voicemail server"
  vpc_id      = var.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 8080
    to_port         = 8080
    security_groups = [aws_security_group.voicemail_alb.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-sg"
  }

  depends_on = [aws_security_group.voicemail_alb]
}

resource "aws_lb_target_group" "voicemail" {
  name        = trim(substr("${var.app_name}-tgt-grp", 0, 32), "-")
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 2 #3
    timeout             = 10 #30
    interval            = 15 #60
    # command             = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
    path    = "/health"
    port    = 8080
    matcher = "200-299"
  }
  deregistration_delay = 10

  tags = {
    Name = "${var.app_name}-target-group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "voicemail" {
  load_balancer_arn = aws_lb.voicemail.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.voicemail.arn
  }
  depends_on = [aws_lb.voicemail, aws_lb_target_group.voicemail]
}


resource "aws_ecs_task_definition" "voicemail" {
  family                   = "${var.app_name}-task"
  network_mode             = "awsvpc" # or "host" if using host networking
  requires_compatibilities = ["EC2"]  # or ["FARGATE"] if using Fargate
  execution_role_arn       = aws_iam_role.voicemail_execution_role.arn
  task_role_arn            = aws_iam_role.voicemail_task_role.arn
  cpu                      = var.cpu    # 2 vCPU
  memory                   = var.memory # 4GB memory

  container_definitions = jsonencode([{
    name      = "${var.app_name}"
    image     = "${var.repository_url}" #:${var.image_tag}"
    essential = true

    portMappings = [
      {
        containerPort = var.voicemail_container_port,
        protocol      = "tcp"
        # hostPort      = var.voicemail_container_port
      }
    ],
    # "healthCheck": {
    #   "command": [
    #     "CMD-SHELL",
    #     "curl -f http://localhost:8080/health || exit 1"
    #     #"fs_cli -x status || exit 1"
    #   ],
    #   "interval": 30,
    #   "timeout": 5,
    #   "retries": 3,
    #   "startPeriod": 60
    # }
    environment = concat(
      [
        {
          name  = "PORT"
          value = tostring(var.voicemail_container_port)
        }
      ],
      var.environment_variables
    ),
    secrets = var.secrets

  }])
  depends_on = [
    aws_iam_role.voicemail_execution_role,
    aws_iam_role.voicemail_task_role,
    aws_iam_role_policy_attachment.voicemail_execution_role_policy,
    aws_iam_role_policy_attachment.voicemail_secrets_policy
  ]
}

resource "aws_ecs_service" "voicemail" {
  name            = "${var.app_name}-service"
  cluster         = var.ecs_cluster #data.aws_ecs_cluster.existing.id
  task_definition = aws_ecs_task_definition.voicemail.arn
  desired_count   = 1
  launch_type     = null

  capacity_provider_strategy {
    capacity_provider = "${var.app_name}-ec2-capacity-provider"
    weight            = 100
    base              = 1
  }

  network_configuration {
    security_groups  = [aws_security_group.voicemail.id]
    subnets          = var.voicemail_admin_dashboard_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.voicemail.arn
    container_name   = var.app_name
    container_port   = 8080
  }

  lifecycle {
    ignore_changes = [
      task_definition # ← prevents roll‑backs
    ]
  }

  force_delete = true

  depends_on = [
    aws_lb_listener.voicemail,
    aws_ecs_cluster_capacity_providers.example,
    aws_ecs_task_definition.voicemail,
    aws_lb_target_group.voicemail
  ]

  tags = {
    Name = "${var.app_name}-service"
  }
}

# Supporting Resources

resource "aws_iam_role" "voicemail_execution_role" {
  name = "ecs-${var.app_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "voicemail_execution_role_policy" {
  role       = aws_iam_role.voicemail_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "voicemail_secrets_policy" {
  role       = aws_iam_role.voicemail_execution_role.name
  policy_arn = aws_iam_policy.voicemail_secrets_access.arn
}

resource "aws_iam_role" "voicemail_task_role" {
  name = "ecs-${var.app_name}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

