variable "project_prefix" { type = string }
variable "environment" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "rds_sg_id" { type = string }
variable "db_engine_version" { type = string }
variable "instance_class" { type = string }
variable "allocated_storage" { type = number }

resource "random_password" "db" {
  length           = 16
  special          = true
  override_special = "_#%^+="
}

resource "aws_secretsmanager_secret" "db" {
  name = "${var.project_prefix}-${var.environment}-db-credentials"
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = "postgres"
    password = random_password.db.result
  })
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.project_prefix}-${var.environment}-dbsubnet"
  subnet_ids = var.private_subnet_ids
}

resource "aws_db_instance" "this" {
  identifier             = "${var.project_prefix}-${var.environment}-pg"
  engine                 = "postgres"
  engine_version         = var.db_engine_version # <- pass from env tf
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.rds_sg_id]
  username               = "postgres"
  password               = random_password.db.result
  publicly_accessible    = false
  skip_final_snapshot    = true
  multi_az               = false
  storage_encrypted      = true
}

output "db_endpoint" { value = aws_db_instance.this.address }
output "secret_arn" { value = aws_secretsmanager_secret.db.arn }
