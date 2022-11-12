provider "aws" {
  profile = "personal"
  region  = "us-east-2"
}

resource "aws_instance" "this" {
  ami           = "ami-0fb653ca2d3203ac1"
  instance_type = terraform.workspace == "default" ? "t2.medium" : "t2.micro"
}

terraform {
  backend "s3" {
    bucket = "tf-state-toks"
    key    = "workspaces/terraform.state"
    region = "us-east-2"
    profile = "personal"

    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

