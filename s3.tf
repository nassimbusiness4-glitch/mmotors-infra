# ============ a.i  BUCKET PUBLIC : site statique ============

resource "aws_s3_bucket" "site" {
  bucket        = var.site_bucket_name
  force_destroy = true # en dev on peut le supprimer même s'il contient des fichiers
}

# par défaut AWS bloque tout accès public -> on l'ouvre pour CE bucket uniquement
resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true # on n'utilise pas les ACL
  ignore_public_acls      = true
  block_public_policy     = false # on autorise une policy publique
  restrict_public_buckets = false
}

# active l'hébergement de site web
resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }
}

# tout le monde peut LIRE les fichiers du site (rien d'autre)
resource "aws_s3_bucket_policy" "site_public_read" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadSite"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.site.arn}/*"
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.site] # sinon AWS refuse la policy
}

# envoie la page d'accueil dans le bucket
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.site.id
  key          = "index.html"
  source       = "${path.module}/site/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.module}/site/index.html") # re-upload si la page change
}

# ============ a.ii  BUCKET PRIVÉ : dossiers d'achat/location ============

resource "aws_s3_bucket" "docs" {
  bucket        = var.docs_bucket_name
  force_destroy = true # dev uniquement, en prod on mettrait false
}

# aucun accès public, jamais
resource "aws_s3_bucket_public_access_block" "docs" {
  bucket                  = aws_s3_bucket.docs.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# chiffrement des fichiers au repos (données perso des clients)
resource "aws_s3_bucket_server_side_encryption_configuration" "docs" {
  bucket = aws_s3_bucket.docs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# garde les anciennes versions -> on peut récupérer un fichier écrasé ou supprimé
resource "aws_s3_bucket_versioning" "docs" {
  bucket = aws_s3_bucket.docs.id

  versioning_configuration {
    status = "Enabled"
  }
}