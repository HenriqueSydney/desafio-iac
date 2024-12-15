
variable "instance_type" {
  description = "Tipo de instância EC2"
  type        = map(string)
  default     = {
    dev        = "t2.micro"
    staging    = "t2.micro"
    prod = "t3.micro"
  }
}

variable "spot_max_price" {
  description = "Preço máximo para Spot Instance"
  default     = 0.0001
}

variable "volume_size" {
  description = "Tamanho do disco em GB"
  default     = {
    dev        = 1
    staging    = 2
    prod = 8
  }
}

variable "cpu_option_core_count" {
  description = "CPU Core Count"
  default     = {
    dev        = 0.5
    staging    = 1
    prod      = 2
  }
}

variable "cpu_option_threads_per_core" {
  description = "CPU Core Count"
  default     = {
    dev        = 0.5
    staging    = 1
    prod      = 2
  }
}

variable "key_name" {
  description = "Nome do par de chaves SSH"
  default = ""
}

variable "subnet_id" {
  type        = string
  description = "Subnet ID"
}