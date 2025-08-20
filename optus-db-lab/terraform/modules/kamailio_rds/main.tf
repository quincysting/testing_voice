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

resource "aws_db_subnet_group" "lab" {
  name       = "${var.app_name}-db-subnet-group"
  subnet_ids = var.subnets

  tags = merge(
    local.tags,
    {
      Name = "${var.app_name}-db-subnet-group"
    }
  )
}

resource "aws_security_group" "db" {
  name        = "${var.app_name}-db-sg"
  description = "Security group for ${var.app_name} RDS cluster"
  vpc_id      = var.vpc_id

  tags = merge(
    local.tags,
    {
      Name = "${var.app_name}-db-sg"
    }
  )
}

resource "aws_security_group_rule" "db_ingress" {
  security_group_id = aws_security_group.db.id
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"] # Allow access from within the VPC
}

resource "aws_security_group_rule" "db_egress" {
  security_group_id = aws_security_group.db.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "db_password" {
  name = "${var.app_name}-db-password-lab"

  tags = merge(
    local.tags,
    {
      Name = "${var.app_name}-db-password-lab"
    }
  )
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

resource "aws_rds_cluster" "lab" {
  cluster_identifier      = "${var.app_name}-cluster"
  engine                  = "aurora-postgresql"
  engine_mode             = "provisioned"
  engine_version          = "13.18"
  database_name           = var.database_name
  master_username         = var.master_username
  master_password         = random_password.db_password.result
  db_subnet_group_name    = aws_db_subnet_group.lab.name
  vpc_security_group_ids  = [aws_security_group.db.id]
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = true
  storage_encrypted       = true
  deletion_protection     = true

  tags = merge(
    local.tags,
    {
      Name = "${var.app_name}-cluster"
    }
  )
}

resource "aws_rds_cluster_instance" "instances" {
  count                = 2
  identifier           = "${var.app_name}-instance-${count.index}"
  cluster_identifier   = aws_rds_cluster.lab.id
  instance_class       = var.instance_class
  engine               = "aurora-postgresql"
  engine_version       = "13.18"
  db_subnet_group_name = aws_db_subnet_group.lab.name

  tags = merge(
    local.tags,
    {
      Name = "${var.app_name}-instance-${count.index}"
    }
  )
}

