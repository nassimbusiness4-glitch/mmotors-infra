# --- général ---

variable "region" {
  description = "Région AWS"
  type        = string
  default     = "eu-west-3" # Paris, clients français
}

variable "project" {
  description = "Nom du projet, sert de préfixe aux ressources"
  type        = string
  default     = "mmotors"
}

variable "environment" {
  description = "Environnement (dev, prod...)"
  type        = string
  default     = "dev"
}

# --- réseau ---

variable "vpc_cidr" {
  description = "Plage d'adresses du VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# 2 zones dispo, obligatoire pour l'ALB et RDS
variable "azs" {
  type    = list(string)
  default = ["eu-west-3a", "eu-west-3b"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"] # ALB + VM de dev
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.11.0/24", "10.0.12.0/24"] # ECS + RDS
}

# NAT = payant (~1,20 $/jour), on peut la couper sans tout casser
variable "enable_nat" {
  type    = bool
  default = false
}

# --- S3 ---

# noms uniques au monde, vérifiés avec "aws s3api head-bucket"
variable "site_bucket_name" {
  type    = string
  default = "mmotors-site-bucket" # public, site statique
}

variable "docs_bucket_name" {
  type    = string
  default = "mmotors-docs-bucket" # privé, dossiers clients
}

# --- base de données (RDS PostgreSQL) ---

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro" # la plus petite, suffisante pour l'ECF
}

variable "db_engine_version" {
  type    = string
  default = "16" # PostgreSQL imposé par l'architecte
}

variable "db_name" {
  type    = string
  default = "mmotors" # base créée vide, prête pour la migration
}

variable "db_username" {
  type    = string
  default = "mmotors_admin" # le mot de passe, lui, est géré par AWS
}

# 7 jours de sauvegardes auto -> couvre le RPO de 24h
variable "db_backup_retention" {
  type    = number
  default = 7
}