module "vpc" {
  source               = "../../modules/vpc"
  project_prefix       = var.project_prefix
  environment          = var.environment
  region               = var.region
  azs                  = ["${var.region}a", "${var.region}b"]
  cidr_block           = "10.${var.environment == "dev" ? 10 : (var.environment == "staging" ? 20 : 30)}.0.0/16"
  public_subnet_cidrs  = ["10.${var.environment == "dev" ? 10 : (var.environment == "staging" ? 20 : 30)}.1.0/24", "10.${var.environment == "dev" ? 10 : (var.environment == "staging" ? 20 : 30)}.2.0/24"]
  private_subnet_cidrs = ["10.${var.environment == "dev" ? 10 : (var.environment == "staging" ? 20 : 30)}.11.0/24", "10.${var.environment == "dev" ? 10 : (var.environment == "staging" ? 20 : 30)}.12.0/24"]
  single_nat_gateway   = true
}

module "security_groups" {
  source           = "../../modules/security_groups"
  vpc_id           = module.vpc.vpc_id
  alb_ingress_cidr = var.allowed_http_cidr
}

module "alb" {
  source                = "../../modules/alb"
  project_prefix        = var.project_prefix
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_sg_id             = module.security_groups.alb_sg_id
  target_group_vpc_id   = module.vpc.vpc_id
  target_instance_sg_id = module.security_groups.ec2_sg_id
  target_instance_ids   = []
}

module "ec2" {
  source              = "../../modules/ec2"
  project_prefix      = var.project_prefix
  environment         = var.environment
  private_subnet_ids  = module.vpc.private_subnet_ids
  instance_type       = "t3.micro"
  alb_sg_id           = module.security_groups.alb_sg_id
  ec2_sg_id           = module.security_groups.ec2_sg_id
  user_data_env_label = upper(var.environment)
  lb_target_group_arn = module.alb.tg_arn
}

module "rds" {
  source             = "../../modules/rds"
  project_prefix     = var.project_prefix
  environment        = var.environment
  private_subnet_ids = module.vpc.private_subnet_ids
  rds_sg_id          = module.security_groups.rds_sg_id
  db_engine_version  = "15.12"
  instance_class     = "db.t4g.micro"
  allocated_storage  = 20
}
