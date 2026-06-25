output "instance_id" {
  value = aws_db_instance.this.id
}

output "instance_arn" {
  value = aws_db_instance.this.arn
}

output "endpoint" {
  value = aws_db_instance.this.address
}

output "port" {
  value = aws_db_instance.this.port
}

output "database_name" {
  value = aws_db_instance.this.db_name
}

output "username" {
  value = aws_db_instance.this.username
}

output "subnet_group_name" {
  value = aws_db_subnet_group.this.name
}