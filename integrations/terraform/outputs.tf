output "instance_public_ip" {
  value       = aws_instance.roche_engine.public_ip
  description = "Public IP address of the Roche engine instance"
}

output "api_endpoint" {
  value       = "http://${aws_instance.roche_engine.public_ip}:8080/api/v1/audit"
  description = "Roche Security Engine API endpoint"
}
