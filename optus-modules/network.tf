# Norwood Lab VPC and Subnets Configuration
data "aws_vpc" "optus-vpc" {
  id = "vpc-0d1467ee215ff5c37"
}

# data "aws_subnets" "all_subnets" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.optus-vpc.id]
#   }
# }

# data "aws_subnet" "filtered" {
#   for_each = toset(data.aws_subnets.all_subnets.ids)
#   id       = each.value
# }

# locals {
#   public_subnets = [
#     for subnet in data.aws_subnet.filtered :
#     subnet.id if can(regex("(?i)public", lookup(subnet.tags, "Name", "")))
#   ]
#   private_subnets = [
#     for subnet in data.aws_subnet.filtered :
#     subnet.id if can(regex("(?i)private", lookup(subnet.tags, "Name", "")))
#   ]
#   database_subnets = [
#     for subnet in data.aws_subnet.filtered :
#     subnet.id if can(regex("(?i)database", lookup(subnet.tags, "Name", "")))
#   ]
# }