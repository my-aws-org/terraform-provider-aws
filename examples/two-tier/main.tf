# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

# Specify the bootstrap file
data "template_file" "bootstrap_nginx" {
  template = "${file("${path.cwd}/bootstrap_nginx.tpl")}"
  #template = "${file("bootstrap_nginx.tpl")}"
}

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

# Create an internet gateway to give our subnet access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

# Create a subnet to launch our instances into
resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# A security group for the ELB so it is accessible via the web
resource "aws_security_group" "elb" {
  name        = "terraform_web_elb"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.default.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "default" {
  name        = "terraform_security_group"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.default.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "web" {
  name = "terraform-web-elb"

  subnets         = ["${aws_subnet.default.id}"]
  security_groups = ["${aws_security_group.elb.id}"]
  instances       = ["${aws_instance.web.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${var.public_key_path}"
}

resource "aws_instance" "web" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "ubuntu"
    host = "${self.public_ip}"
    # The connection will use the local SSH agent for authentication.
  }

  instance_type = "t3.micro"

  # Lookup the correct AMI based on the region
  # we specified
  ami = "${lookup(var.aws_amis, var.aws_region)}"

  # The name of our SSH keypair we created above.
  key_name = "${aws_key_pair.auth.id}"

  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.default.id}"]

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = "${aws_subnet.default.id}"

  user_data_base64 = << EOF
  IyEvYmluL2Jhc2gKICBleHBvcnQgUEFUSD0kUEFUSDovdXNyL2xvY2FsL2JpbgogIHN1ZG8gYXB0LWdldCAteSBpbnN0YWxsIHdnZXQKICBsb2NhbF9pcD1gd2dldCAtcSAtTyAtIGh0dHA6Ly8xNjkuMjU0LjE2OS4yNTQvbGF0ZXN0L21ldGEtZGF0YS9sb2NhbC1pcHY0YAogIEhPU1ROQU1FPXRoaXJ1X25naW54LSRsb2NhbF9pcAogIGhvc3RuYW1lICRIT1NUTkFNRQogIGVjaG8gIkhPU1ROQU1FPSRIT1NUTkFNRSIgPiAvZXRjL2hvc3RuYW1lCiAgZWNobyAiSE9TVE5BTUU9JEhPU1ROQU1FIiA+PiAvZXRjL3N5c2NvbmZpZy9uZXR3b3JrCiAgaG9zdG5hbWVjdGwgc2V0LWhvc3RuYW1lICRIT1NUTkFNRSAtLXN0YXRpYwogIGVjaG8gInByZXNlcnZlX2hvc3RuYW1lOiB0cnVlIiA+PiAvZXRjL2Nsb3VkL2Nsb3VkLmNmZwogIHN1ZG8gYXB0LWdldCB1cGRhdGUKICBzdWRvIGFwdC1nZXQgaW5zdGFsbCBuZ2lueAogIHN1ZG8gc2VydmljZSBuZ2lueCByZXN0YXJ0
  EOF

  tags = {
		name = "terraform-firsts"	
		cost-center = "free"
	}

}