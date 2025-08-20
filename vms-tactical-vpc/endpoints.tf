locals {
  endpoint_sg_name = "${local.vpc_name}-vpc-endpoint"
}

resource "aws_security_group" "vpc_endpoint" {
  name        = local.endpoint_sg_name
  description = "Security group for VPC endpoints in ${local.vpc_name}"
  vpc_id      = module.vms_tactical.vpc_id

  tags = merge(local.tags, {
    Name = local.endpoint_sg_name
  })
}

resource "aws_security_group_rule" "vpc_endpoint_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = module.vms_tactical.vpc_cidrs
  security_group_id = aws_security_group.vpc_endpoint.id
}

locals {
  endpoints = [
    "ec2",
    "ec2messages",
    "ecs",
    "ecr.api",
    "ecr.dkr",
    "elasticache",
    "elasticloadbalancing",
    "logs",
    "rds",
    "secretsmanager",
    "ssm",
    "ssmmessages",
    "sts"
  ]
}

resource "aws_vpc_endpoint" "this" {
  for_each = toset(local.endpoints)

  vpc_id              = module.vms_tactical.vpc_id
  subnet_ids          = [module.vms_tactical.subnets["vpce-2a"].id]
  service_name        = "com.amazonaws.${data.aws_region.this.name}.${each.value}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.vpc_endpoint.id]
}

locals {
  gateway_endpoints = [
    "s3",
    "dynamodb",
  ]
}

resource "aws_vpc_endpoint" "gateway" {
  for_each = toset(local.gateway_endpoints)

  vpc_id            = module.vms_tactical.vpc_id
  route_table_ids   = [module.vms_tactical.route_tables["routeable"].id]
  service_name      = "com.amazonaws.${data.aws_region.this.name}.${each.value}"
  vpc_endpoint_type = "Gateway"
}