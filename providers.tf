# versions minimales pour éviter les surprises
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # reste en 6.x, pas de passage auto en 7
    }
  }
}

provider "aws" {
  region = var.region # Paris, voir variables.tf

  # tags mis partout automatiquement -> pratique pour filtrer les coûts plus tard
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}