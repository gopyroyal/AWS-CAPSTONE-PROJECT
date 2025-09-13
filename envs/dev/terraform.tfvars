project_prefix = "gopi-capstone"
environment    = "dev"
region         = "ca-central-1"
azs            = ["ca-central-1a", "ca-central-1b"]

vpc_cidr             = "10.10.0.0/16"
public_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24"]
private_subnet_cidrs = ["10.10.11.0/24", "10.10.12.0/24"]
single_nat_gateway   = true

instance_type     = "t3.micro"
db_engine_version = "15.7"
db_instance_class = "db.t4g.micro"
allocated_storage = 20
