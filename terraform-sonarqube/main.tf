data "terraform_remote_state" "main" {
  backend = "s3"
  config = {
    bucket = "task-manager-tfstate-infra"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.terraform_remote_state.main.outputs.vpc_id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}
