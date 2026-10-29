# adresse de l'application (ALB)
output "alb_url" {
  value = "http://${aws_lb.main.dns_name}"
}

# adresse du site statique
output "site_url" {
  value = "http://${aws_s3_bucket_website_configuration.site.website_endpoint}"
}

# adresse de la base
output "db_endpoint" {
  value = aws_db_instance.main.address
}

# IP publique de la VM de dev
output "dev_vm_ip" {
  value = aws_instance.dev.public_ip
}