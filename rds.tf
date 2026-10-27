# ============ c. DaaS PostgreSQL (RDS) ============

# la base vit uniquement dans les 2 subnets privés (2 zones = obligatoire pour RDS)
resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-db-subnets"
  subnet_ids = aws_subnet.private[*].id
}

# pare-feu de la base : seul le port PostgreSQL, et seulement depuis le VPC
resource "aws_security_group" "rds" {
  name        = "${var.project}-rds-sg"
  description = "Acces PostgreSQL depuis le VPC uniquement"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "PostgreSQL depuis le VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # on resserrera sur ECS au bloc 5
  }
}

resource "aws_db_instance" "main" {
  identifier     = "${var.project}-db"
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true # données clients chiffrées sur le disque

  db_name  = var.db_name
  username = var.db_username
  # AWS génère le mot de passe et le range dans Secrets Manager
  # -> il n'apparaît ni dans le code ni dans le tfstate
  manage_master_user_password = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false # jamais joignable depuis internet
  multi_az               = false # 1 seule zone pour le coût (en prod : true)

  # sauvegardes auto chaque nuit -> RPO 24h respecté
  backup_retention_period = var.db_backup_retention
  backup_window           = "01:00-02:00" # heure UTC, la nuit en France

  # dev uniquement : on peut supprimer sans snapshot final
  skip_final_snapshot = true
  deletion_protection = false
  apply_immediately   = true
}