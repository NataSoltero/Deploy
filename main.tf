provider "aws" {
	region = "${var.region}"
	shared_credentials_file = "/home/vagrant/.aws/credentials"
	profile = "default"
}

data "aws_availability_zones" "all" {}

#VPC
resource "aws_vpc" "demo" {
	cidr_block = "10.0.0.0/16"
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
	cidr_block = "10.0.16.0/20"
	availability_zone = "us-west-2a"
}

#Backsubnet
resource "aws_subnet" "backdemo" {
	vpc_id = "${aws_vpc.demo.id}"
	cidr_block = "10.0.32.0/20"
	availability_zone = "us-west-2b"
}

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

resource "aws_security_group" "elb" {
    name = "demo-example-elb"
	vpc_id = "${aws_vpc.demo.id}"
    
	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	
    egress {
        from_port = 0  
        to_port = 0
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
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
                value = "ELK"
                propagate_at_launch = true
        }
}

#Launch Configuration
resource "aws_launch_configuration" "elasticsearch" {
        image_id = "ami-ba602bc2"
        instance_type = "t2.medium"
        security_groups = ["${aws_security_group.allow_all.id}"]
        key_name = "demo"
        root_block_device {
                volume_size = 30
        }

        name = "Elasticsearch Server"

        user_data = <<-EOF
				#!/bin/bash
				sudo adduser vagrant --home /home/vagrant --shell /bin/bash 
				echo "vagrant:password" | sudo chpasswd
				sudo mkdir /home/vagrant/.ssh
				sudo chown vagrant:vagrant /home/vagrant/.ssh
				sudo chmod 700 /home/vagrant/.ssh
				sudo touch /home/vagrant/.ssh/authorized_keys
				sudo chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
				sudo chmod 600 /home/vagrant/.ssh/authorized_keys
				sudo echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCu9a4YwarFt87Z4Tuf39ElIdo/N7hRCyKSKEUvvsRbmrDtKywFJguTsI0pQ9lQE3lPGUPygr0WI2+yd7JewVm2cfixX9ZAN7odFHeIRlWRMk5tVjT+rJAe89xwnd7ReoFt9sJuzo/mlFRdW3mB/YgQWDFgmMzHJRByZBhhGfDVoNGSSZD4g16kEQ3bnXiNdQcvQvOEIn3t0gCnaXMQNJpRlBJPLB0JrR+Fxcxe3G0/V7+x0jrmQV1X/TBHM400wQWIG1udoSICepvrM7WO3xbTWvcSbbSYJVLhmeaz94VcMrGXSp+iJRpyet3WWYEUjDxeZ+PqbA8seGJ48UHFAelv vagrant@jenkinsdemo" > /home/vagrant/.ssh/authorized_keys
				sudo echo "vagrant ALL=(ALL)    NOPASSWD: ALL"  >> /etc/sudoers
				sudo apt-get -y install python-gdbm
				sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.5 1
				sudo update-alternatives --install /usr/bin/python python /usr/bin/python2.7 10
				sudo apt-get clean
				sudo update-alternatives --config python
				#sudo add-apt-repository ppa:webupd8team/java -y
				sudo apt-get update
				#echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections
				#echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 seen true" | debconf-set-selections
				#sudo apt-get -y install oracle-java8-installer
				#cd /var/lib/dpkg/info
				#sed -i 's|JAVA_VERSION=8u171|JAVA_VERSION=8u181|' oracle-java8-installer.*
				#sed -i 's|J_DIR=jdk1.8.0_171|J_DIR=jdk1.8.0_181|' oracle-java8-installer.*
				#sed -i 's|PARTNER_URL=http://download.oracle.com/otn-pub/java/jdk/8u171-b11/512cd62ec5174c3487ac17c61aaa89e8/|PARTNER_URL=http://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/|' oracle-java8-installer.*
				#sed -i 's|SHA256SUM_TGZ="b6dd2837efaaec4109b36cfbb94a774db100029f98b0d78be68c27bec0275982"|SHA256SUM_TGZ="1845567095bfbfebd42ed0d09397939796d05456290fb20a83c476ba09f991d3"|' oracle-java8-installer.*
				#sudo apt-get update
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
