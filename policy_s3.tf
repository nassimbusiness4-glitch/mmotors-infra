# Rôle porté par l'appli quand elle tourne dans ECS
resource "aws_iam_role" "ecs_task" {
  name = "${var.project}-ecs-task-role"

  # Seules les tâches ECS peuvent porter ce rôle
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Droit de lire les dossiers du bucket privé, rien d'autre
resource "aws_iam_role_policy" "read_docs" {
  name = "${var.project}-read-docs"
  role = aws_iam_role.ecs_task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Voir la liste des fichiers du bucket
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.docs.arn
      },
      {
        # Lire un fichier du bucket
        Effect   = "Allow"
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.docs.arn}/*"
      }
    ]
  })
}