provider "aws" {
  region = "us-east-2"
}

module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  cluster_name = "webservers-stage"
  db_remote_state_bucket = "tf-state-toks"
  db_remote_state_key = "stage/data-stores/mysql/terraform.state"

  instance_type = "t2.micro"
  min_size = 2
  max_size = 2
}

resource "aws_security_group_rule" "allow_testing" {
  type = "ingress"
  security_group_id = module.webserver_cluster.alb_security_group_id

  from_port = 12345
  to_port = 12345
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

terraform {
  backend "s3" {
    bucket  = "tf-state-toks"
    key     = "stage/services/webserver-cluster/terraform.tfstate"
    region  = "us-east-2"
    profile = "personal"

    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}