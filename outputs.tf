output "secret_arns" {
  description = "Mapa de ARNs de secretos"
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.arn }
}

output "secret_names" {
  description = "Mapa de nombres de secretos"
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.name }
}

output "secret_ids" {
  description = "Mapa de IDs"
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.id }
}