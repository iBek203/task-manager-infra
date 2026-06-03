terraform {
  backend "s3" {
    bucket       = "task-manager-tfstate-infra"
    key          = "bootstrap/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
