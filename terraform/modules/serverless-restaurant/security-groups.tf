resource "aws_security_group" "rds_sg" {
  name = "rds-sg"
  description = "Allow inbound access to RDS from vpc"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = var.db_port
    to_port     = var.db_port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
