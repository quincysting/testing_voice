locals {
  tags = {
    o_b_bu         = "networks"
    o_b_pri-own    = "Alfred Lam"
    o_b_bus-own    = "James Burden"
    o_t_app-plat   = "networks"
    o_t_app        = "voicemail"
    o_t_env        = "poc"
    o_t_app-own    = "Brian Easson"
    o_t_tech-own   = "Serena Feng"
    o_b_cc         = "gk881infra"
    o_s_app-class  = "cat2"
    o_b_project    = "VMS"
    o_s_data-class = "conf_non_pii"
    o_t_app-role   = "app"
    o_a_avail      = "24x7"
    o_s_sra        = "00642"
    o_t_dep-mthd   = "hybrid"
    o_t_lifecycle  = "inbuild"
  }
}

resource "aws_elasticache_subnet_group" "lab" {
  name       = "${var.app_name}-cache-subnet-group"
  subnet_ids = var.subnets
}

resource "aws_security_group" "redis" {
  name        = "${var.app_name}-sg"
  description = "Security group for ${var.app_name} Redis cluster"
  vpc_id      = var.vpc_id

  tags = merge(
    local.tags,
    {
      Name = "${var.app_name}-security-roup"
    }
  )
}

resource "aws_security_group_rule" "redis_ingress" {
  security_group_id = aws_security_group.redis.id
  type              = "ingress"
  from_port         = 6379
  to_port           = 6379
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"] # Allow access from within the VPC
}

resource "aws_security_group_rule" "redis_egress" {
  security_group_id = aws_security_group.redis.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id       = var.app_name
  description                = "Redis cluster for ${var.app_name}"
  node_type                  = var.node_type
  num_cache_clusters         = 2
  automatic_failover_enabled = true
  engine                     = "redis"
  engine_version             = var.engine_version
  parameter_group_name       = var.parameter_group_name
  subnet_group_name          = aws_elasticache_subnet_group.lab.name
  security_group_ids         = [aws_security_group.redis.id]
  apply_immediately          = true
  port                       = 6379
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  tags = merge(
    local.tags,
    {
      Name = "${var.app_name}-replication-group"
    }
  )
}
