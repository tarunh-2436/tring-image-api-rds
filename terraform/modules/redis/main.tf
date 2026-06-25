###############################################
# Redis Subnet Group
###############################################

resource "aws_elasticache_subnet_group" "this" {

  name = "${var.identifier}-subnet-group"

  subnet_ids = var.subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.identifier}-subnet-group"
    }
  )
}

###############################################
# Redis Replication Group
###############################################

resource "aws_elasticache_replication_group" "this" {

  replication_group_id = var.identifier

  description = "Redis replication group"

  engine = "redis"

  engine_version = "7.1"

  node_type = var.node_type

  num_cache_clusters = 1

  port = 6379

  subnet_group_name = aws_elasticache_subnet_group.this.name

  security_group_ids = var.security_group_ids

  automatic_failover_enabled = false

  multi_az_enabled = false

  transit_encryption_enabled = true

  at_rest_encryption_enabled = true

  apply_immediately = true

  auto_minor_version_upgrade = true

  tags = merge(
    var.tags,
    {
      Name = var.identifier
    }
  )
}