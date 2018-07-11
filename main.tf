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
	root_block_device { 
		volume_size = 30
	}
	
	name = "Elasticsearch Server"
	
	user_data = <<-EOF
			#!/bin/bash
			sudo yum install -y java
			sudo useradd vagrant -U -s /bin/bash
			sudo mkdir /home/vagrant/.ssh
			sudo chown vagrant:vagrant /home/vagrant/.ssh
			sudo chmod 700 /home/vagrant/.ssh
			sudo touch /home/vagrant/.ssh/authorized_keys
			sudo chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
			sudo chmod 600 /home/vagrant/.ssh/authorized_keys
			sudo echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCu9a4YwarFt87Z4Tuf39ElIdo/N7hRCyKSKEUvvsRbmrDtKywFJguTsI0pQ9lQE3lPGUPygr0WI2+yd7JewVm2cfixX9ZAN7odFHeIRlWRMk5tVjT+rJAe89xwnd7ReoFt9sJuzo/mlFRdW3mB/YgQWDFgmMzHJRByZBhhGfDVoNGSSZD4g16kEQ3bnXiNdQcvQvOEIn3t0gCnaXMQNJpRlBJPLB0JrR+Fxcxe3G0/V7+x0jrmQV1X/TBHM400wQWIG1udoSICepvrM7WO3xbTWvcSbbSYJVLhmeaz94VcMrGXSp+iJRpyet3WWYEUjDxeZ+PqbA8seGJ48UHFAelv vagrant@jenkinsdemo" > /home/vagrant/.ssh/authorized_keys
			sudo echo "vagrant ALL=(ALL)	NOPASSWD: ALL"  >> /etc/sudoers
			sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
			sudo touch /etc/yum.repos.d/elastic.repo
			sudo echo "[elasticsearch-6.x]
			name=Elasticsearch repository for 6.x packages
			baseurl=https://artifacts.elastic.co/packages/6.x/yum
			gpgcheck=1
			gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
			enabled=1
			autorefresh=1
			type=rpm-md" > /etc/yum.repos.d/elastic.repo
			EOF
	
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
