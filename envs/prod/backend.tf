terraform {
  backend "s3" {
    bucket         = "gopi-capstone-terraform-state"
    key            = "state/prod/terraform.tfstate"
    region         = "ca-central-1"
    dynamodb_table = "gopi-capstone-terraform-lock"
    encrypt        = true
  }
}
