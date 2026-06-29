output "replication_group_id" {
  value = aws_elasticache_replication_group.this.id
}

output "arn" {
  value = aws_elasticache_replication_group.this.arn
}

output "primary_endpoint" {
  value = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint" {
  value = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "port" {
  value = aws_elasticache_replication_group.this.port
}

output "subnet_group_name" {
  value = aws_elasticache_subnet_group.this.name
}

output "cache_cluster_id" {
  value = tolist(
    aws_elasticache_replication_group.this.member_clusters
  )[0]
}