output "subnet_ids" {
  value = aws_subnet.subnets[*].id
  sensitive = false
  description = "Subnets para o LoadBalancer"
}

