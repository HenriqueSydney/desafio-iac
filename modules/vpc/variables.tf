variable "public_subnet_count" {
  description = "Number of public subnets to create"
  default     = 2
}

variable "vpc_cidr_block" {
  description = "CIDR block para a VPC em seus respectivos ambientes"
  type        = map(string)
  default     = {
    dev        = "10.0.0.0/17"
    staging    = "10.0.0.0/17"
    prod = "10.0.0.0/17"
  }
}
