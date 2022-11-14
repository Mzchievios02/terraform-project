provider "aws" {
  region = "us-east-2"
}

module "webserver_cluser" {
  source = "../../../../modules/services/webserver-cluster"

  cluster_name           = "webservers-prod"
  db_remote_state_bucket = "tf-state-toks"
  db_remote_state_key    = "prod/data-stores/mysql/terraform.state"

  instance_type = "t2.micro"
  min_size      = 2
  max_size      = 2
}

resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
  scheduled_action_name = "scale_out_during_business_hours"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 10
  recurrence            = "0 9 * * *"

  autoscaling_group_name = module.webserver_cluser.asg_name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
  scheduled_action_name = "scale_in_at_night"
  min_size              = 2
  max_size              = 10
  desired_capacity      = 2
  recurrence            = "0 17 * * *"

  autoscaling_group_name = module.webserver_cluser.asg_name
}

terraform {
  backend "s3" {
    bucket  = "tf-state-toks"
    key     = "prod/services/webserver-cluster/terraform.tfstate"
    region  = "us-east-2"
    profile = "personal"

    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}