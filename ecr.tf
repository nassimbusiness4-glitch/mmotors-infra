# Entrepôt privé pour ranger les images Docker de l'appli
resource "aws_ecr_repository" "app" {
  name         = "${var.project}-app"
  force_delete = true

  # AWS vérifie l'image à chaque envoi
  image_scanning_configuration {
    scan_on_push = true
  }
}