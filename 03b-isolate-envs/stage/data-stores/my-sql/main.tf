provider "aws" {
  region  = "us-east-2"
  profile = "personal"
}

terraform {
  backend "s3" {
    bucket  = "tf-state-toks"
    key     = "stage/data-stores/mysql/terraform.state"
    region  = "us-east-2"
    profile = "personal"

    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

resource "aws_db_instance" "this" {
  identifier_prefix   = "terraform-up-example"
  engine              = "mysql"
  allocated_storage   = 10
  instance_class      = "db.t2.micro"
  skip_final_snapshot = true
  db_name             = "example_database"

  username = var.db_username
  password = var.db_password
}