output "instance_id" {
  description = "ID da instância criada"
  value       = aws_instance.ec2.id
  sensitive = true
}

output "public_ip" {
  description = "Endereço IP público da instância"
  value       = aws_instance.ec2.public_ip
  sensitive = false
}