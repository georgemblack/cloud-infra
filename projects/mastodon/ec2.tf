resource "aws_launch_template" "main" {
  name          = "masotodon-lt"
  image_id      = "ami-0652d397074720eb1"
  instance_type = "t4g.nano"
  key_name      = "secure-shellfish"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2.id]
  }
}

resource "aws_autoscaling_group" "main" {
  name                = "mastodon-asg"
  max_size            = 1
  min_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = [aws_subnet.main_subnet_2a.id]

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
  }
}

resource "aws_security_group" "ec2" {
  name   = "mastodon-ec2-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description      = "Public SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "mastodon-ec2-sg"
  }
}
