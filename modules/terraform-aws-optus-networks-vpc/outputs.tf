output "route_tables" {
  description = "A map of route table IDs created in the VPC."
  value       = aws_route_table.this
}

output "subnets" {
  description = "A list of subnet IDs created in the VPC."
  value       = aws_subnet.this
}

output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidrs" {
  description = "The primary and secondary CIDR blocks associated with the VPC."
  value       = concat([aws_vpc.this.cidr_block], [for assoc in aws_vpc_ipv4_cidr_block_association.this : assoc.cidr_block])
}
