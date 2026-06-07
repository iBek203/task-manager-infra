resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg"
  description = "PostgreSQL access for RDS"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "rds_postgres" {
  security_group_id = aws_security_group.rds.id
  description       = "PostgreSQL from VPC"
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr
}

resource "aws_vpc_security_group_egress_rule" "rds_all" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-rds"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "main" {
  identifier        = "${var.project}-postgres"
  engine            = "postgres"
  engine_version    = "18"
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  storage_encrypted = true

  db_name  = "taskdb"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot = true
  publicly_accessible = false
}
