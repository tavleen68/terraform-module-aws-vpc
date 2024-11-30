output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "aws_nat_gateway_id" {
  value = aws_nat_gateway.this[*].id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.this[*].id
}

output "private_route_table_ids" {
  value = aws_route_table.private[*].id
}

output "public_route_table_ids" {
  value = aws_route_table.public[*].id
}

output "transit_gateway_attachment_id" {
  value = aws_ec2_transit_gateway_vpc_attachment.this[*].id
}