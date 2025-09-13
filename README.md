# Gopi Capstone — Multi-Environment AWS Terraform (ca-central-1)

This repository provisions a **scalable multi-environment web infrastructure** on AWS using Terraform.

**Environments:** `dev`, `staging`, `prod`  
**Region:** `ca-central-1`  
**Prefix:** `gopi-capstone`

## What gets created
- VPC with public/private subnets, IGW, single NAT
- Security Groups for ALB, EC2, RDS
- Public ALB -> EC2 AutoScaling (Amazon Linux 2023, Nginx landing page labeled by env)
- RDS PostgreSQL 15 (db.t4g.micro), credentials in Secrets Manager
- Remote state in S3 with DynamoDB table lock
- GitHub Actions CI/CD using OIDC (no long-lived AWS keys)

## Quick start (AWS CloudShell)
```bash
unzip gopi-capstone.zip -d ~/ && cd ~/gopi-capstone
./bootstrap.sh

# Deploy each environment locally (optional; CI also applies on main)
cd envs/dev && terraform init && terraform apply -auto-approve && cd ../..
cd envs/staging && terraform init && terraform apply -auto-approve && cd ../..
cd envs/prod && terraform init && terraform apply -auto-approve && cd ../..

# ALB DNS names will be in outputs
```

## CI/CD (GitHub Actions)
1. Create a GitHub repo and push this folder.
2. In repo Settings → Secrets and variables → Actions, add:
   - `AWS_ROLE_ARN` = `arn:aws:iam::<your-account-id>:role/gopi-capstone-github-oidc-role`
3. On PRs: `fmt`, `validate`, `plan` run for all envs.  
   On merge to `main`: `apply` runs for all envs.

## Clean up
```bash
terraform -chdir=envs/prod destroy -auto-approve
terraform -chdir=envs/staging destroy -auto-approve
terraform -chdir=envs/dev destroy -auto-approve
```


## If Terraform is missing in CloudShell
```bash
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo dnf -y install terraform
terraform -version
```

## One-shot deploy/destroy (all envs)
```bash
./deploy_all.sh
# ...
./destroy_all.sh
```
