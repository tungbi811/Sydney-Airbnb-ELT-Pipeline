resource "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_security_group" "rds" {
  name        = "airbnb-rds"
  description = "Postgres access from my IP"
}

resource "aws_vpc_security_group_ingress_rule" "postgres" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = "${var.my_ip}/32"
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
}

resource "aws_db_instance" "airbnb" {
  identifier             = "airbnb-tf"
  engine                 = "postgres"
  engine_version         = "18.3"
  instance_class         = "db.t4g.micro"
  allocated_storage      = 20
  storage_type           = "gp3"
  username               = "tung"
  db_name                = "airbnb"
  password               = random_password.db.result
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true
}