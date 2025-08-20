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
