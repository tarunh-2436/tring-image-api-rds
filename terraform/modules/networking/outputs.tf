output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "VPC ARN"
  value       = aws_vpc.this.arn
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value = [
    aws_subnet.public[0].id,
    aws_subnet.public[1].id
  ]
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value = [
    aws_subnet.private[0].id,
    aws_subnet.private[1].id
  ]
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "private_route_table_ids" {
  value = [
    aws_route_table.private[0].id,
    aws_route_table.private[1].id
  ]
}