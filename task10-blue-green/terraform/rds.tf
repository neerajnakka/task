# ============================================================================
# RDS DATABASE SUBNET GROUP
# ============================================================================
# A subnet group tells RDS which subnets it can use
# We use PRIVATE subnets for security (database not exposed to internet)

resource "aws_db_subnet_group" "default" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id  # Use both private subnets
  
  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# ============================================================================
# RDS POSTGRESQL DATABASE INSTANCE
# ============================================================================
# This creates a managed PostgreSQL database on AWS
# AWS handles backups, patches, and maintenance

resource "aws_db_instance" "default" {
  # Basic Configuration
  identifier     = "${var.project_name}-db"
  engine         = "postgres"
  engine_version = "16.3"
  instance_class = "db.t3.micro"  # Small instance (free tier eligible)
  
  # Database Credentials
  db_name  = "strapi_ecs_db"
  username = "strapi"
  password = var.db_password
  
  # Storage Configuration
  allocated_storage = 20  # 20 GB storage
  storage_type      = "gp3"  # General purpose SSD
  
  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false  # Not accessible from internet (secure)
  
  # Backup Configuration
  backup_retention_period = 1  # Free tier allows 1 day retention
  backup_window           = "03:00-04:00"  # Backup at 3 AM UTC
  
  # Maintenance Configuration
  maintenance_window = "mon:04:00-mon:05:00"  # Maintenance on Monday 4 AM UTC
  
  # Deletion Protection
  skip_final_snapshot       = true  # Don't create snapshot on deletion (for dev/test)
  # For production, set skip_final_snapshot = false
  
  # Parameter Group
  parameter_group_name = "default.postgres16"
  
  tags = {
    Name = "${var.project_name}-db"
  }
}


