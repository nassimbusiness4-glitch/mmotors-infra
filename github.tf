# Demande à AWS mon numéro de compte (comme aws sts get-caller-identity)
data "aws_caller_identity" "current" {}

# Utilisateur réservé au pipeline GitHub Actions
resource "aws_iam_user" "github" {
  name = "${var.project}-github-actions"
}

# Ses droits : envoyer des images sur ECR et relancer le service ECS, rien d'autre
resource "aws_iam_user_policy" "github" {
  name = "${var.project}-github-deploy"
  user = aws_iam_user.github.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Se connecter à ECR
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        # Envoyer une image, seulement dans notre dépôt
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]
        Resource = aws_ecr_repository.app.arn
      },
      {
        # Relancer notre service ECS, seulement le nôtre
        Effect   = "Allow"
        Action   = ["ecs:UpdateService", "ecs:DescribeServices"]
        Resource = "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${var.project}-cluster/${var.project}-app"
      }
    ]
  })
}