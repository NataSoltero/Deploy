provider "aws" {
	region = "${var.region}"
	shared_credentials_file = "/home/vagrant/.aws/credentials"
	profile = "default"
}

data "aws_availability_zones" "all" {}

#VPC
resource "aws_vpc" "demo" {
	cidr_block = "192.0.0.0/16"
}

#Gateway
resource "aws_internet_gateway" "demo" {
	vpc_id = "${aws_vpc.demo.id}"
}

#Internet access
resource "aws_route" "internet_access" {
	route_table_id = "${aws_vpc.demo.main_route_table_id}"
	destination_cidr_block = "0.0.0.0/0"
	gateway_id = "${aws_internet_gateway.demo.id}"
}

#Subnet
resource "aws_subnet" "demo" {
	vpc_id = "${aws_vpc.demo.id}"
	cidr_block = "192.0.16.0/20"
	availability_zone = "us-west-2a"
}

#Backsubnet
resource "aws_subnet" "backdemo" {
	vpc_id = "${aws_vpc.demo.id}"
	cidr_block = "192.0.32.0/20"
	availability_zone = "us-west-2b"
}

#ELB
resource "aws_elb" "demo" {
	name = "terraform-asg-demo"
	subnets = ["${aws_subnet.demo.id}","${aws_subnet.backdemo.id}"]
	cross_zone_load_balancing = true
	
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
	vpc_zone_identifier = ["${aws_subnet.demo.id}", "${aws_subnet.backdemo.id}"]
	load_balancers = ["${aws_elb.demo.id}"]
	
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
	security_groups = ["${aws_security_group.elasticsearch.id}"]
	
	name = "Elasticsearch Server"
	
	lifecycle {
		create_before_destroy = true
	}
}

#SG
resource "aws_security_group" "elasticsearch" {
	name = "terraform_elasticsearch"
	vpc_id = "${aws_vpc.demo.id}"
		
#ssh from anywhere
	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

#http access from the vpc
	ingress {
		from_port = 8080
		to_port = 8080
		protocol = "tcp"
		cidr_blocks = ["192.0.0.0/16"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
	
	lifecycle {
		create_before_destroy = true
	}
}

#ASG Logstash
resource "aws_autoscaling_group" "logstash" {
	launch_configuration = "${aws_launch_configuration.logstash.id}"
	vpc_zone_identifier = ["${aws_subnet.demo.id}", "${aws_subnet.backdemo.id}"]
	load_balancers = ["${aws_elb.demo.id}"]
	
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
	security_groups = ["${aws_security_group.logstash.id}"]
	
	name = "Logstash Server"
	
	lifecycle {
		create_before_destroy = true
	}
}

#SG Logstash
resource "aws_security_group" "logstash" {
	name = "terraform_logstash"
	vpc_id = "${aws_vpc.demo.id}"
		
#ssh from anywhere
	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

#http access from the vpc
	ingress {
		from_port = 8080
		to_port = 8080
		protocol = "tcp"
		cidr_blocks = ["192.0.0.0/16"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
	
	lifecycle {
		create_before_destroy = true
	}
}

#ASG Kibana
resource "aws_autoscaling_group" "kibana" {
	launch_configuration = "${aws_launch_configuration.kibana.id}"
	vpc_zone_identifier = ["${aws_subnet.demo.id}", "${aws_subnet.backdemo.id}"]
	load_balancers = ["${aws_elb.demo.id}"]
	
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
	security_groups = ["${aws_security_group.kibana.id}"]
	
	name = "Kibana Server"
	
	lifecycle {
		create_before_destroy = true
	}
}

#SG Kibana
resource "aws_security_group" "kibana" {
	name = "terraform_kibana"
	vpc_id = "${aws_vpc.demo.id}"
		
#ssh from anywhere
	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

#http access from the vpc
	ingress {
		from_port = 8080
		to_port = 8080
		protocol = "tcp"
		cidr_blocks = ["192.0.0.0/16"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
	
	lifecycle {
		create_before_destroy = true
	}
}

#ASG Web
resource "aws_autoscaling_group" "web" {
	launch_configuration = "${aws_launch_configuration.web.id}"
	vpc_zone_identifier = ["${aws_subnet.demo.id}", "${aws_subnet.backdemo.id}"]
	load_balancers = ["${aws_elb.demo.id}"]
	
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
	security_groups = ["${aws_security_group.web.id}"]
	
	name = "Web Server"
	
	lifecycle {
		create_before_destroy = true
	}
}

#SG Web
resource "aws_security_group" "web" {
	name = "terraform_web"
	vpc_id = "${aws_vpc.demo.id}"
		
#ssh from anywhere
	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

#http access from the vpc
	ingress {
		from_port = 8080
		to_port = 8080
		protocol = "tcp"
		cidr_blocks = ["192.0.0.0/16"]
	}

	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}
	
	lifecycle {
		create_before_destroy = true
	}
}
