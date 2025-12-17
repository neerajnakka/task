resource "aws_db_subnet_group" "default" {
  name       = "strapi-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "strapi-db-subnet-group"
  }
}

resource "aws_db_instance" "default" {
  identifier           = "strapi-postgres-db"
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = "15.10" 
  instance_class       = "db.t3.micro"
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.postgres15"
  skip_final_snapshot  = true
  publicly_accessible  = false # Secure! Only accessible from Private Subnets (ECS)

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name

  tags = {
    Name = "strapi-postgres"
  }
}
