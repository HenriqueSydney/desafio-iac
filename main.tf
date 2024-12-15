module "vpc" {
  source = "./modules/vpc"
}

module "load_balancer" {
  source     = "./modules/load_balancer"
  subnets    = module.vpc.subnet_ids
  depends_on = [module.vpc]
}

module "ec2" {
  source     = "./modules/ec2"
  subnet_id  = module.vpc.subnet_ids[0]
  depends_on = [module.vpc]
}
