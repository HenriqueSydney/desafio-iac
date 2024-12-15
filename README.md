### Desafio RocketSeat 
## Configuração de Infraestrutura Multi-Ambiente - AWS - IaC

Neste projeto será feita a configuração de uma infra com o terraform, 
com ambientes de `production`, `dev` e `staging`, cada um com suas respectivas 
`vpc`, `ec2` e `lb`, provisionados de acordo com as necessidades dos ambientes.

## Estrutura do projeto

```
modules
├── ec2
│   ├── datasources.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── variables.tf
├── vpc
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
├── load_balancer
    ├── main.tf
    ├── variables.tf
provider.tf
main.tf
```

### Diferentes ambientes
Inicie o projeto criando 3 WorkSpaces: dev, staging e prod. Selecione o Workspace dev para trabalhar:
```sh
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
terraform workspace select dev
```


## modules/vpc

As variáveis dos blocos de IPs serão geradas conforme a quantidade de subnets. Cada ambiente poderá ter uma configuração diferente na VPC e nas para rodar o Load Balance
```docker
# modules/vpc/variables.tf
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
```

Criação da VPC, Subnets e Gateway para o Load Balance
```docker
# modules/vpc/main.tf
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr_block[terraform.workspace]
  instance_tenancy = "default"

  tags = {
    Name        = "Main VPC"
    Iac = true
    Environment = "${terraform.workspace}"
  }
}

resource "aws_subnet" "subnets" {
  count                   = var.public_subnet_count
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr_block[terraform.workspace], 8, count.index)
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet-${count.index + 1}"
    Iac = true
    Environment = "${terraform.workspace}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    IaC = true
    Environment = "${terraform.workspace}"
  }
}
```

Export o subnet_id para ser usado depois na EC2 e LB
```docker
# modules/vpc/outputs.tf
output "subnet_ids" {
  value = aws_subnet.subnets[*].id
  sensitive = false
  description = "Subnets para o LoadBalancer"
}

```

Neste ponto podemos rodar os comandos:

```sh
terraform init # para instalar o módulo vpc
terraform fmt # para garantir o lint do nosso projeto
terraform validate # para garantir que os comandos estão corretos
terraform plan # para um dry run e ver o impacto das alterações
terraform apply -auto-approve # para aplicar as alterações
```

## modules/ec2
Agora vamos criar nossa EC2, primeiro, criando um lookup para buscar uma AMI de ubuntu atualizada
```docker
# modules/ec2/datasources.tf
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
```

Agora as variáveis para poder definir um tamanho de instância para cada ambiente, bem como os recursos alocados para cada instância
```docker
# modules/ec2/variables.tf

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
```

Finalmente, criar o recurso propriamente dito, usando nossa vpc criada previamente

```docker
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
```

Novamente, vamos rodar os comandos do terraform para conferir se tudo foi feito corretamente

```sh
terraform init # para instalar o módulo ec2
terraform fmt # para garantir o lint do nosso projeto
terraform validate # para garantir que os comandos estão corretos
terraform plan # para um dry run e ver o impacto das alterações
terraform apply -auto-approve # para aplicar as alterações
```

Finalmente vamos criar o load balance, declarando as variáveis que vamos usar

```docker
# modules/lb/variables.tf
vvariable "subnets" {
  description = "Subnets to associate with the load balancer"
  type        = list(string)
}
```

E então criar o recurso, na mesma rede

```docker
# modules/lb/main.tf
esource "aws_lb" "load_balancer" {
  name               = "load-balancer"
  internal           = false
  load_balancer_type = "application"

  dynamic "subnet_mapping" {
    for_each = var.subnets
    content {
      subnet_id = subnet_mapping.value
    }
  }

  tags = {
    Name        = "Load Balancer"
    Environment = "${terraform.workspace}"
    IaC = true
  }
}
```

Agora, rodar os comandos para persistir na nuvem as alterações da infra

```sh
terraform init # para instalar o módulo lb
terraform fmt # para garantir o lint do nosso projeto
terraform validate # para garantir que os comandos estão corretos
terraform plan # para um dry run e ver o impacto das alterações
terraform apply -auto-approve # para aplicar as alterações
```