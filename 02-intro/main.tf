provider "aws" {
  region = "us-east-2"
  profile = "personal"
}

resource "aws_launch_configuration" "this" {
  image_id = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
  security_groups  = [aws_security_group.instance.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p ${var.server_port} &
              EOF
  
  # Required when using a launch configuration with an auto scaling group
  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_group" "this" {
    launch_configuration = aws_launch_configuration.this.name
    vpc_zone_identifier = data.aws_subnets.default.ids

    target_group_arns = [aws_lb_target_group.asg.arn]
    health_check_type = "ELB"

    max_size = 5
    min_size = 2

    tag {
        key = "Name"
        value = "terraform-asg-example"
        propagate_at_launch = true
    }
  
}

resource "aws_lb" "this" {
  name = "aws-lb-terraform"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default.ids
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port = 80
  protocol = "HTTP"

  # Retrun 404 if the requests don't match port80
  default_action {
    type = "fixed-response"

    fixed_response {
    content_type = "text/plain"
    message_body = "404: page not found"
    status_code = 404
    }
  }
}

resource "aws_security_group" "alb" {
  name = "terraform-example-alb"

  # Allow inbound HTTP requests
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound requests
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "asg" {
  name = "terraform-asg-example"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
        values = ["*"]
    }
  }
  action {
    type = "forward"
    target_group_arn =  aws_lb_target_group.asg.arn
  }
}
resource "aws_security_group" "instance" {
  name = "terraform-example-instance"

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = var.server_port
    protocol = "tcp"
    to_port = var.server_port
  }
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = 8080
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
  description = "The domain name of the load balancer"
}

data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}