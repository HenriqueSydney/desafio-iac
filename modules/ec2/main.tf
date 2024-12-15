
resource "aws_instance" "ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type[terraform.workspace]
  subnet_id     = var.subnet_id

  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = var.spot_max_price
    }
  }

  root_block_device {
    volume_size = var.volume_size      # Tamanho do disco em GB
    volume_type = "gp2"   # Tipo do volume (gp2, gp3, io1, etc.)
    encrypted   = true    # Criptografia habilitada
  }

  cpu_options {
    core_count       = var.cpu_option_core_count
    threads_per_core = var.cpu_option_threads_per_core
  }

  tags = {
    Name = "EC2"
    Iac = true
    Environment = "${terraform.workspace}" # Prod, Staging, ou Dev
  }
}
