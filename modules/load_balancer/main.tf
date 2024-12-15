resource "aws_lb" "load_balancer" {
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
