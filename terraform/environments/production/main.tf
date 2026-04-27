module "vpc" {
  source              = "../../modules/vpc"
  env_name            = "production"
  project_name        = "multi-env-platform"
  vpc_cidr            = "10.1.0.0/16"
  public_subnet_cidr  = "10.1.1.0/24"
  private_subnet_cidr = "10.1.2.0/24"
  az                  = "us-east-1a"
}

module "security_groups" {
  source   = "../../modules/security_groups"
  env_name = "production"
  vpc_id   = module.vpc.vpc_id
  your_ip  = var.your_ip
}

module "ec2" {
  source           = "../../modules/ec2"
  env_name         = "production"
  public_subnet_id = module.vpc.public_subnet_id
  key_name         = var.key_name
  app_sg_id        = module.security_groups.app_sg_id
  db_sg_id         = module.security_groups.db_sg_id
}