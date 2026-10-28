# ============ d. planification de la VM de dev ============
# off de 20h à 8h + tout le week-end (demandé par l'architecte)

# rôle utilisé par le "réveil" AWS (EventBridge Scheduler)
resource "aws_iam_role" "scheduler" {
  name = "${var.project}-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# il a le droit de démarrer/arrêter CETTE VM uniquement
resource "aws_iam_role_policy" "scheduler_ec2" {
  name = "start-stop-dev-vm"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ec2:StartInstances", "ec2:StopInstances"]
      Resource = aws_instance.dev.arn
    }]
  })
}

# démarrage du lundi au vendredi à 8h (heure de Paris)
resource "aws_scheduler_schedule" "start_dev" {
  name                         = "${var.project}-dev-start"
  schedule_expression          = "cron(0 8 ? * MON-FRI *)"
  schedule_expression_timezone = "Europe/Paris"

  flexible_time_window {
    mode = "OFF" # pile à l'heure
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:startInstances"
    role_arn = aws_iam_role.scheduler.arn
    input    = jsonencode({ InstanceIds = [aws_instance.dev.id] })
  }
}

# arrêt du lundi au vendredi à 20h -> rien le samedi/dimanche = off tout le week-end
resource "aws_scheduler_schedule" "stop_dev" {
  name                         = "${var.project}-dev-stop"
  schedule_expression          = "cron(0 20 ? * MON-FRI *)"
  schedule_expression_timezone = "Europe/Paris"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = "arn:aws:scheduler:::aws-sdk:ec2:stopInstances"
    role_arn = aws_iam_role.scheduler.arn
    input    = jsonencode({ InstanceIds = [aws_instance.dev.id] })
  }
}