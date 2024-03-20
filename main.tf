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
  publicly_accessible           = true
}

resource "aws_iam_role" "rds_proxy_role" {
  name = "rds_proxy_role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "rds.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  })
}

resource "aws_iam_policy" "rds_proxy_policy" {
  name        = "rds-proxy-policy"
  description = "Policy for RDS Proxy access"
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "rds-db:connect",
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_proxy_attach" {
  role       = aws_iam_role.rds_proxy_role.name
  policy_arn = aws_iam_policy.rds_proxy_policy.arn
}

resource "aws_db_proxy" "rds_proxy" {
  name                                                   = "rdsproxy"
  debug_logging                                          = false
  engine_family                                          = "POSTGRESQL"
  idle_client_timeout                                    = 1800
  require_tls                                            = true
  role_arn                                               = aws_iam_role.rds_proxy_role.arn
  vpc_security_group_ids                                 = var.vpc_security_group_ids
  vpc_subnet_ids                                         = var.subnet_ids

  auth {
    auth_scheme                                          = "SECRETS"
    description                                          = "example"
    iam_auth                                             = "DISABLED"
    secret_arn                                           = "arn:aws:secretsmanager:us-east-2:644237782704:secret:mikes/db/db_credentials-6wQzyQ"
  }
  depends_on                                             = [aws_db_instance.database]
}

resource "aws_db_proxy_default_target_group" "rds_proxy_tg" {
  db_proxy_name = aws_db_proxy.rds_proxy.name
  connection_pool_config {
    connection_borrow_timeout        = 30
    max_connections_percent          = 20
    max_idle_connections_percent     = 20
  }
}

resource "aws_db_proxy_target" "rds_proxy_tg" {
  db_proxy_name           = aws_db_proxy.rds_proxy.name
  target_group_name       = aws_db_proxy_default_target_group.rds_proxy_tg.name
  db_instance_identifier  = aws_db_instance.database.identifier
}

data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = var.db_credentials_arn
}