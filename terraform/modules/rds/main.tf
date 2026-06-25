###############################################
# DB Subnet Group
###############################################

resource "aws_db_subnet_group" "this" {

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
# PostgreSQL RDS Instance
###############################################

resource "aws_db_instance" "this" {

  identifier = var.identifier

  engine         = "postgres"
  engine_version = "17"

  instance_class = var.instance_class

  allocated_storage = var.allocated_storage
  storage_type      = "gp3"

  db_name  = var.database_name
  username = var.username
  password = var.password

  db_subnet_group_name = aws_db_subnet_group.this.name

  vpc_security_group_ids = var.security_group_ids

  publicly_accessible = false

  multi_az = false

  backup_retention_period = 7

  deletion_protection = false

  storage_encrypted = true

  performance_insights_enabled = true

  auto_minor_version_upgrade = true

  apply_immediately = true

  skip_final_snapshot = true

  copy_tags_to_snapshot = true

  tags = merge(
    var.tags,
    {
      Name = var.identifier
    }
  )
}