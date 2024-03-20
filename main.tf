provider "aws" {
  region = var.region
}

resource "aws_db_subnet_group" "database" {
  name       = var.aws_db_subnet_group_name
  subnet_ids = var.subnet_ids
}

# Declare o recurso aws_vpc para que a referência seja válida
resource "aws_vpc" "mikes_private_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_db_instance" "database" {
  identifier                    = var.db_identifier
  allocated_storage             = var.db_allocated_storage
  db_name                       = var.db_name
  engine                        = "postgres"
  engine_version                = "16.1"
  instance_class                = "db.t3.micro"
  username                      = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)["username"]
  password                      = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)["password"]
  skip_final_snapshot           = true
  allow_major_version_upgrade   = true
  db_subnet_group_name          = aws_db_subnet_group.database.name
  apply_immediately             = true
  vpc_security_group_ids        = var.vpc_security_group_ids
}

resource "aws_rds_cluster" "rds-proxy-test" {
  availability_zones           = ["us-east-2a", "us-east-2b", "us-east-2c"]
  cluster_identifier           = "rds-proxy-test"
  database_name                = var.db_name
  db_subnet_group_name         = aws_db_subnet_group.database.id
  engine                       = "postgres"
  master_password              = "123456"
  master_username              = "postgres"
  skip_final_snapshot          = true
  vpc_security_group_ids       = var.vpc_security_group_ids
  allocated_storage            = 20  # 20 GB of storage
  db_cluster_instance_class    = "db.t3.micro"  # Instance class for the cluster
}

resource "aws_rds_cluster_instance" "rds-proxy-test" {
  cluster_identifier           = aws_rds_cluster.rds-proxy-test.id
  db_subnet_group_name         = aws_db_subnet_group.database.id
  engine                       = "postgres"
  identifier                   = "rds-proxy-test-a"
  instance_class               = "db.t3.micro"
  publicly_accessible          = "true"
}


data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = var.db_credentials_arn
}