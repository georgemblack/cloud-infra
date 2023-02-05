# resource "aws_security_group" "db" {
#   name   = "mastodon-db-sg"
#   vpc_id = aws_vpc.main.id

#   ingress {
#     description      = "Public SSH"
#     from_port        = 22
#     to_port          = 22
#     protocol         = "tcp"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   egress {
#     from_port        = 0
#     to_port          = 0
#     protocol         = "-1"
#     cidr_blocks      = ["0.0.0.0/0"]
#     ipv6_cidr_blocks = ["::/0"]
#   }

#   tags = {
#     Name = "mastodon-db-sg"
#   }
# }
