# VPC Flow Logs Configuration
resource "aws_flow_log" "vpc_flow_log" {
  count = var.enable_flow_log ? 1 : 0

  iam_role_arn    = var.flow_log_destination_type == "cloud-watch-logs" ? aws_iam_role.flow_log[0].arn : null
  log_destination = var.flow_log_destination_type == "cloud-watch-logs" ? aws_cloudwatch_log_group.vpc_flow_log[0].arn : var.flow_log_s3_arn
  log_destination_type = var.flow_log_destination_type
  vpc_id          = aws_vpc.this.id
  traffic_type    = var.flow_log_traffic_type

  log_format = var.flow_log_format

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-flow-logs"
  })
}

# CloudWatch Log Group for VPC Flow Logs (only if using CloudWatch)
resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  count = var.enable_flow_log && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name              = "/aws/vpc/flowlogs/${var.vpc_name}"
  retention_in_days = var.flow_log_retention_days

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-flow-logs"
  })
}

# IAM Role for VPC Flow Logs (only if using CloudWatch)
resource "aws_iam_role" "flow_log" {
  count = var.enable_flow_log && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name = "${var.vpc_name}-flow-log-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-flow-log-role"
  })
}

# IAM Policy for VPC Flow Logs CloudWatch access
resource "aws_iam_role_policy" "flow_log" {
  count = var.enable_flow_log && var.flow_log_destination_type == "cloud-watch-logs" ? 1 : 0

  name = "${var.vpc_name}-flow-log-policy"
  role = aws_iam_role.flow_log[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Existing VPC resources
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = var.vpc_name
  })
}

resource "aws_vpc_ipv4_cidr_block_association" "this" {
  for_each = toset(var.vpc_secondary_cidrs)

  vpc_id     = aws_vpc.this.id
  cidr_block = each.value
}

resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id = aws_vpc.this.id

  availability_zone       = each.value.availability_zone
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-${each.key}"
  })
}

resource "aws_route_table" "this" {
  for_each = var.route_tables

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.vpc_name}-${each.key}"
  })
}

resource "aws_route_table_association" "this" {
  for_each = { for k, v in var.subnets : k => v if v.route_table != "default" }

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.this[each.value.route_table].id
}

locals {
  routes_map = flatten([for k, v in var.route_tables : [
    for route in v.routes : [
      merge(route, {
        key         = "${k}-${route.destination}"
        route_table = k
      })]]])

  routes = { for route in local.routes_map : route.key => route }
}

resource "aws_route" "this" {
  for_each = local.routes

  route_table_id         = aws_route_table.this[each.value.route_table].id
  destination_cidr_block = each.value.destination
  transit_gateway_id     = try(each.value.transit_gateway_id, null)
}