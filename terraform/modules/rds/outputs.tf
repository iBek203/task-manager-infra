output "endpoint" {
  description = "Hostname of the RDS PostgreSQL instance."
  value       = aws_db_instance.main.address
  sensitive   = true
}
