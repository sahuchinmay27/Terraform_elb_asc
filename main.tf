provider "aws" {
  region     = "ap-south-1"
}

data "aws_availability_zones" "all" {}

### Creating EC2 instance
resource "aws_instance" "web" {
  ami               = "${lookup(var.amis,var.region)}"
  count             = "${var.counts}"
  key_name               = "${var.key_name}"
  vpc_security_group_ids = ["${aws_security_group.instance.id}"]
  source_dest_check = false
  instance_type = "t2.micro"

  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "${var.key_name}"
    host     = self.public_ip
  }
  
  provisioner "remote-exec" {
    inline = [
      "sudo yum update –y",
      "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo",
      "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key",
      "sudo yum upgrade",
      "sudo amazon-linux-extras install java-openjdk11 -y",
      "sudo yum install jenkins -y",
      "sudo systemctl enable jenkins",
      "sudo systemctl start jenkins",
      "sudo systemctl status jenkins",  
    ]
  }
}

### Creating Security Group for EC2
resource "aws_security_group" "instance" {
  name = "terraform-instance"
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## Creating Launch Configuration
resource "aws_launch_configuration" "example" {
  image_id               = "${lookup(var.amis,var.region)}"
  instance_type          = "t2.micro"
  security_groups        = ["${aws_security_group.instance.id}"]
  key_name               = "${var.key_name}"
  
}

## Creating AutoScaling Group
resource "aws_autoscaling_group" "my_autoscle" {
  launch_configuration = "${aws_launch_configuration.example.id}"
  availability_zones = "${data.aws_availability_zones.all.names}"
  min_size = 2
  max_size = 10
  load_balancers = ["${aws_elb.my_elb.name}"]
  health_check_type = "ELB"
  tag {
    key = "Name"
    value = "terraform-asg-my"
    propagate_at_launch = true
  }
}

## Security Group for ELB
resource "aws_security_group" "elb" {
  name = "terraform-my-elb"
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
### Creating ELB
resource "aws_elb" "my_elb" {
  name = "terraform-asg-my"
  security_groups = ["${aws_security_group.elb.id}"]
  availability_zones = "${data.aws_availability_zones.all.names}"
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:8080/"
  }
  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "8080"
    instance_protocol = "http"
  }
}