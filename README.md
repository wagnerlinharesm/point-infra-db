# Infraestrutura do Banco de Dados

## Descrição Geral

Este documento descreve a infraestrutura do banco de dados utilizada no projeto. A infraestrutura consiste em um banco de dados PostgreSQL hospedado na AWS.

## Tecnologias Utilizadas

- PostgreSQL
- AWS RDS (Relational Database Service)

## Detalhes da Infraestrutura

A infraestrutura do banco de dados é provisionada utilizando o Terraform e está configurada da seguinte forma:

1 - Backend do Terraform: O estado do Terraform é armazenado no S3 para garantir a consistência e segurança do estado.

```hcl
terraform {
  backend "s3" {
    bucket = "point-terraform-state"
    key    = "point-db.tfstate"
    region = "us-east-2"
    encrypt = true
  }
}
```

2 - Provider AWS: Utilizamos o provedor AWS para provisionar os recursos na AWS.

```hcl
provider "aws" {
  region = var.region
}
```

3 - Grupo de Sub-redes do Banco de Dados: Criamos um grupo de sub-redes do banco de dados para especificar as sub-redes nas quais o banco de dados será lançado.

```hcl
resource "aws_db_subnet_group" "database" {
  name       = var.aws_db_subnet_group_name
  subnet_ids = var.subnet_ids
}
```

4 - Instância do Banco de Dados: Provisionamos uma instância do banco de dados PostgreSQL na AWS RDS.

```hcl
resource "aws_db_instance" "database" {
  identifier                    = var.db_identifier
  allocated_storage             = var.db_allocated_storage
  db_name                       = var.db_name
  engine                        = "postgres"
  engine_version                = "14"
  instance_class                = "db.t3.micro"
  username                      = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)["username"]
  password                      = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)["password"]
  skip_final_snapshot           = true
  allow_major_version_upgrade   = true
  db_subnet_group_name          = aws_db_subnet_group.database.name
  apply_immediately             = true
  vpc_security_group_ids        = var.vpc_security_group_ids
}
```

5 - Secrets Manager para Credenciais do Banco de Dados: Utilizamos o AWS Secrets Manager para armazenar as credenciais do banco de dados de forma segura.

```hcl
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = var.db_credentials_arn
}
```

## Parâmetros de Configuração

`region`: Região da AWS onde a infraestrutura será provisionada (padrão: us-east-2).
`aws_db_subnet_group_name`: Nome do grupo de sub-redes do banco de dados.
`subnet_ids`: IDs das sub-redes onde o banco de dados será lançado.
`db_identifier`: Identificador único da instância do banco de dados.
`db_allocated_storage`: Espaço de armazenamento alocado para o banco de dados em GB.
`db_name`: Nome do banco de dados.
vpc_security_group_ids: IDs dos grupos de segurança da VPC para acesso ao banco de dados.
`db_credentials_arn`: ARN do Secrets Manager que armazena as credenciais do banco de dados.

## Tabelas para a solução de Ponto
![Tabelas](doc/banco-de-dados.png)