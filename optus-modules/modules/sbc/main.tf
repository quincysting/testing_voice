# Kamailio resources

# Kamailio Module
# All configuration and secrets are managed externally and referenced from shared-config.tf
# This module only provisions infrastructure and references existing parameters/secrets

data "aws_launch_template" "existing" {
  filter {
    name   = "tag:Name"
    values = ["mozart-${var.environment}-launch_template"]
    #values = ["mozart-lab-launch_template"]
  }
}

# data "aws_ecs_cluster" "existing" {
#   cluster_name = "mozart-lab-cluster"
# }

resource "aws_autoscaling_group" "ecs-lab-kamailio" {
  name                = "${var.app_name}-asg"
  vpc_zone_identifier = var.sbc_fs_subnets
  # launch_template = data.aws_launch_template.existing.id
  min_size         = 2
  max_size         = 3
  desired_capacity = 2

  launch_template {
    id      = data.aws_launch_template.existing.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.app_name}-ecs-instance"
    propagate_at_launch = true
  }

  depends_on = [data.aws_launch_template.existing,aws_lb_listener.kamailio]
}

resource "aws_ecs_capacity_provider" "ec2" {
  name = "${var.app_name}-ec2-capacity-provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs-lab-kamailio.arn

    managed_scaling {
      maximum_scaling_step_size = 1000
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = var.ecs_cluster

  #capacity_providers = [var.kamailio_ec2_capacity_provider_name,var.voicemail_ec2_capacity_provider_name,aws_ecs_capacity_provider.ec2.name]

  #capacity_providers = [var.kamailio_ec2_capacity_provider_name, var.voicemail_ec2_capacity_provider_name, var.imap_ec2_capacity_provider_name, "mozart-vmail-lab-ec2-capacity-provider", aws_ecs_capacity_provider.ec2.name]

  capacity_providers = [aws_ecs_capacity_provider.ec2.name]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.ec2.name
  }
  depends_on = [aws_ecs_capacity_provider.ec2]
  lifecycle {
    ignore_changes = [capacity_providers, default_capacity_provider_strategy]
  }
}

#resource "aws_ecs_cluster_capacity_providers" "example" {
#  cluster_name = data.aws_ecs_cluster.existing.cluster_name

#  capacity_providers = [aws_ecs_capacity_provider.ec2.name]

#  default_capacity_provider_strategy {
#    base              = 1
#    weight            = 100
#    capacity_provider = aws_ecs_capacity_provider.ec2.name
#  }
#}

resource "aws_iam_policy" "kamailio_secrets_access" {
  name        = "${var.app_name}-secrets-access"
  description = "Allow kamailio ECS tasks to access Secrets Manager"

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

resource "aws_security_group" "kamailio_nlb" {
  name        = "${var.app_name}-nlb-sg"
  description = "Allow SIP traffic for kamailio server"
  vpc_id      = var.vpc_id


  dynamic "ingress" {
    for_each = [
      { protocol = "tcp", port = var.kamailio_container_port },
      { protocol = "udp", port = var.kamailio_container_port },
      { protocol = "tcp", port = 5061 } # TLS port
    ]
    content {
      protocol    = ingress.value.protocol
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      cidr_blocks = ["0.0.0.0/0"] # to be updated after receiving subnets information
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
    Name = "${var.app_name}-nlb-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "kamailio" {
  name               = trim(substr("${var.app_name}-nlb", 0, 32), "-")
  internal           = true
  load_balancer_type = "network"
  security_groups    = [aws_security_group.kamailio_nlb.id]
  subnets            = var.alb_subnets
  depends_on = [aws_security_group.kamailio_nlb]
  tags = {
    Name = "${var.app_name}-nlb"
  }
}

resource "aws_security_group" "kamailio" {
  name        = "${var.app_name}-sg"
  description = "Allow inbound access from the NLB only for kamailio server"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = [
      { protocol = "tcp", port = var.kamailio_container_port },
      { protocol = "udp", port = var.kamailio_container_port },
      { protocol = "tcp", port = 5061 }, # TLS port
      { protocol = "tcp", port = 5065 } # health check port
    ]
    content {
      protocol        = ingress.value.protocol
      from_port       = ingress.value.port
      to_port         = ingress.value.port
      security_groups = [aws_security_group.kamailio_nlb.id]
      description     = "Allow ${ingress.value.protocol} ${ingress.value.port}"
    }
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  depends_on = [aws_security_group.kamailio_nlb]
  tags = {
    Name = "${var.app_name}-sg"
  }
}

resource "aws_lb_target_group" "kamailio" {
  name        = trim(substr("${var.app_name}-tgt-grp", 0, 32), "-")
  port        = var.kamailio_container_port
  protocol    = "UDP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 30
    interval            = 60
    port                = "5065"
  }

  tags = {
    Name = "${var.app_name}-target-group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "kamailio" {
  load_balancer_arn = aws_lb.kamailio.arn
  port              = var.kamailio_container_port
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kamailio.arn
  }
  depends_on = [
    aws_lb.kamailio,
    aws_lb_target_group.kamailio
  ]
}


resource "aws_ecs_task_definition" "kamailio" {
  family                   = "${var.app_name}-task"
  network_mode             = "awsvpc" # or "host" if using host networking
  requires_compatibilities = ["EC2"]  # or ["FARGATE"] if using Fargate
  execution_role_arn       = aws_iam_role.kamailio_execution_role.arn
  task_role_arn            = aws_iam_role.kamailio_task_role.arn
  cpu                      = var.cpu    # 2 vCPU
  memory                   = var.memory # 4GB memory

  container_definitions = jsonencode([{
    name      = "${var.app_name}"
    image     = "${var.repository_url}:${var.image_tag}"
    essential = true

    portMappings = [
      {
        containerPort = var.kamailio_container_port
        hostPort      = var.kamailio_container_port
        protocol      = "udp"
      },
      {
        containerPort = 5065
        hostPort      = 5065
        protocol      = "tcp"
      },
      {
        containerPort = 5061
        hostPort      = 5061
        protocol      = "tcp"
      }
    ]

    environment = var.environment_variables
    secrets     = var.secrets

  }])
  depends_on = [
    aws_iam_role.kamailio_execution_role,
    aws_iam_role.kamailio_task_role,
    aws_iam_role_policy_attachment.kamailio_execution_role_policy,
    aws_iam_role_policy_attachment.kamailio_secrets_policy
  ]
}

resource "aws_ecs_service" "kamailio" {
  name            = "${var.app_name}-service"
  cluster         = var.ecs_cluster #data.aws_ecs_cluster.existing.id
  task_definition = aws_ecs_task_definition.kamailio.arn
  desired_count   = 1
  launch_type     = null

  capacity_provider_strategy {
    capacity_provider = "${var.app_name}-ec2-capacity-provider"
    weight            = 100
    base              = 1
  }

  network_configuration {
    security_groups  = [aws_security_group.kamailio.id]
    subnets          = var.sbc_fs_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.kamailio.arn
    container_name   = var.app_name
    container_port   = var.kamailio_container_port
  }

  # lifecycle {
  #   ignore_changes = [
  #     task_definition     # ← prevents roll‑backs
  #   ]
  # }

  depends_on = [
    aws_lb_listener.kamailio,
    aws_ecs_cluster_capacity_providers.example,
    aws_ecs_task_definition.kamailio,
    aws_lb_target_group.kamailio
  ]

  tags = {
    Name = "${var.app_name}-service"
  }
}

# Supporting Resources

resource "aws_iam_role" "kamailio_execution_role" {
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

resource "aws_iam_role_policy_attachment" "kamailio_execution_role_policy" {
  role       = aws_iam_role.kamailio_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "kamailio_secrets_policy" {
  role       = aws_iam_role.kamailio_execution_role.name
  policy_arn = aws_iam_policy.kamailio_secrets_access.arn
}

resource "aws_iam_role" "kamailio_task_role" {
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


