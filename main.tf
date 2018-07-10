provider "aws" {
	region = "${var.region}"
	shared_credentials_file = "/home/vagrant/.aws/credentials"
	profile = "default"
}

data "aws_availability_zones" "all" {}

#ELB
resource "aws_elb" "demo" {
	name = "terraform-asg-demo"
	cross_zone_load_balancing = true
	availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
	
	health_check {
		healthy_threshold = 2
		unhealthy_threshold = 3
		timeout = 3
		interval = 30
		target = "tcp:22"
	}

	listener {
		lb_port = 80
		lb_protocol = "http"
        instance_port = "80"
		instance_protocol = "http"
	}
}

#ASG Elasticsearch
resource "aws_autoscaling_group" "elasticsearch" {
	launch_configuration = "${aws_launch_configuration.elasticsearch.id}"
	load_balancers = ["${aws_elb.demo.id}"]
	availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
	
	desired_capacity = 1
	min_size = 1
	max_size = 5
	health_check_grace_period = 300
	health_check_type = "ELB"
	
	tag{
		key = "Name"
		value = "Elasticsearch"
		propagate_at_launch = true
	}
}

#Launch Configuration
resource "aws_launch_configuration" "elasticsearch" {
	image_id = "ami-28e07e50"
	instance_type = "t2.micro"
	security_groups = ["${aws_security_group.allow_all.id}"]
	key_name = "demo"
	
	name = "Elasticsearch Server"
	
	lifecycle {
		create_before_destroy = true
	}
}

#SG
resource "aws_security_group" "allow_all" {
  name = "allow_all"
  description = "Allow all inbound traffic"
  
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

#ASG Logstash
resource "aws_autoscaling_group" "logstash" {
	launch_configuration = "${aws_launch_configuration.logstash.id}"
	load_balancers = ["${aws_elb.demo.id}"]
	availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
	
	desired_capacity = 1
	min_size = 1
	max_size = 5
	health_check_grace_period = 300
	health_check_type = "ELB"
	
	tag{
		key = "Name"
		value = "Logstash"
		propagate_at_launch = true
	}
}

#Launch Configuration Logstash
resource "aws_launch_configuration" "logstash" {
	image_id = "ami-28e07e50"
	instance_type = "t2.micro"
	security_groups = ["${aws_security_group.allow_all.id}"]
	key_name = "demo"
	
	name = "Logstash Server"
	
	lifecycle {
		create_before_destroy = true
	}
}

#ASG Kibana
resource "aws_autoscaling_group" "kibana" {
	launch_configuration = "${aws_launch_configuration.kibana.id}"
	load_balancers = ["${aws_elb.demo.id}"]
	availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
	
	desired_capacity = 1
	min_size = 1
	max_size = 5
	health_check_grace_period = 300
	health_check_type = "ELB"
	
	tag{
		key = "Name"
		value = "Kibana"
		propagate_at_launch = true
	}
}

#Launch Configuration Kibana
resource "aws_launch_configuration" "kibana" {
	image_id = "ami-28e07e50"
	instance_type = "t2.micro"
	security_groups = ["${aws_security_group.allow_all.id}"]
	key_name = "demo"
	
	name = "Kibana Server"
	
	lifecycle {
		create_before_destroy = true
	}
}

#ASG Web
resource "aws_autoscaling_group" "web" {
	launch_configuration = "${aws_launch_configuration.web.id}"
	load_balancers = ["${aws_elb.demo.id}"]
	availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
	
	desired_capacity = 1
	min_size = 1
	max_size = 5
	health_check_grace_period = 300
	health_check_type = "ELB"
	
	tag{
		key = "Name"
		value = "Web"
		propagate_at_launch = true
	}
}

#Launch Configuration Web
resource "aws_launch_configuration" "web" {
	image_id = "ami-28e07e50"
	instance_type = "t2.micro"
	security_groups = ["${aws_security_group.allow_all.id}"]
	key_name = "demo"
		
	name = "Web Server"
	
	lifecycle {
		create_before_destroy = true
	}
}
