resource "aws_security_group" "app_sg" {
  name   = "${var.env_name}-app-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.your_ip]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = { Name = "{$var.env_name}-app-sg" }
}

resource "aws_security_group" "db_sg" {
  name        = "${var.env_name}-db-sg"
  description = "Database security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432 # or 3306 for MySQL
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
