# --- alertes par e-mail ---

# La liste de diffusion des alertes
resource "aws_sns_topic" "alerts" {
  name = "${var.project}-alertes"
}

# Mon e-mail, abonné à la liste (il faudra confirmer le lien reçu par mail)
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# --- métriques hardware ---

# CPU des conteneurs : alerte si plus de 80 % pendant 10 minutes
resource "aws_cloudwatch_metric_alarm" "ecs_cpu" {
  alarm_name        = "${var.project}-ecs-cpu-eleve"
  alarm_description = "CPU des conteneurs ECS au-dessus de 80 %"
  namespace         = "AWS/ECS"
  metric_name       = "CPUUtilization"
  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.app.name
  }
  statistic           = "Average"
  period              = 300 # une mesure toutes les 5 minutes
  evaluation_periods  = 2   # 2 mesures de suite = 10 minutes
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# Espace disque libre de la base : alerte s'il reste moins de 2 Go
resource "aws_cloudwatch_metric_alarm" "rds_disque" {
  alarm_name        = "${var.project}-rds-disque-faible"
  alarm_description = "Moins de 2 Go libres sur la base RDS"
  namespace         = "AWS/RDS"
  metric_name       = "FreeStorageSpace"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.main.identifier
  }
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 2000000000 # 2 Go, en octets
  comparison_operator = "LessThanThreshold"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# --- métriques applicatives ---

# Compte les lignes "ERROR" dans les logs de l'appli
resource "aws_cloudwatch_log_metric_filter" "erreurs_app" {
  name           = "${var.project}-erreurs-app"
  log_group_name = aws_cloudwatch_log_group.app.name
  pattern        = "ERROR"

  metric_transformation {
    name      = "ErreursApp"
    namespace = "MMotors/Application"
    value     = "1" # chaque ligne trouvée compte pour 1
  }
}

# Alerte dès qu'il y a au moins 1 erreur en 5 minutes
resource "aws_cloudwatch_metric_alarm" "erreurs_app" {
  alarm_name          = "${var.project}-erreurs-dans-les-logs"
  alarm_description   = "Erreurs trouvées dans les logs de l'appli"
  namespace           = "MMotors/Application"
  metric_name         = "ErreursApp"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching" # pas de log d'erreur = tout va bien
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# Temps de réponse de la page d'accueil (chemin critique) : alerte si plus d'1 seconde
resource "aws_cloudwatch_metric_alarm" "temps_reponse" {
  alarm_name        = "${var.project}-appli-lente"
  alarm_description = "Temps de réponse moyen de l'appli au-dessus d'1 seconde"
  namespace         = "AWS/ApplicationELB"
  metric_name       = "TargetResponseTime"
  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 1 # en secondes
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching" # pas de visite = rien à mesurer
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# --- métriques FinOps ---

# Budget mensuel du compte, avec alerte sur le coût réel et le coût prévu
resource "aws_budgets_budget" "mensuel" {
  name         = "${var.project}-budget-mensuel"
  budget_type  = "COST"
  limit_amount = "20"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Coût réel : alerte quand 80 % du budget est déjà dépensé
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  # Coût prévu : alerte si la fin du mois risque de dépasser le budget
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}

# --- tableau de bord ---

# Une page CloudWatch avec les 4 courbes et l'état des alarmes
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project}-supervision"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title   = "Hardware - CPU des conteneurs (%)"
          region  = var.region, stat = "Average", period = 300
          metrics = [["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.main.name, "ServiceName", aws_ecs_service.app.name]]
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title   = "Hardware - Espace disque libre de la base (octets)"
          region  = var.region, stat = "Minimum", period = 300
          metrics = [["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", aws_db_instance.main.identifier]]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title   = "Applicatif - Erreurs dans les logs"
          region  = var.region, stat = "Sum", period = 300
          metrics = [["MMotors/Application", "ErreursApp"]]
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title   = "Applicatif - Temps de réponse de la page d'accueil (s)"
          region  = var.region, stat = "Average", period = 300
          metrics = [["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", aws_lb.main.arn_suffix]]
        }
      },
      {
        type = "alarm", x = 0, y = 12, width = 24, height = 4
        properties = {
          title = "Etat des alarmes"
          alarms = [
            aws_cloudwatch_metric_alarm.ecs_cpu.arn,
            aws_cloudwatch_metric_alarm.rds_disque.arn,
            aws_cloudwatch_metric_alarm.erreurs_app.arn,
            aws_cloudwatch_metric_alarm.temps_reponse.arn
          ]
        }
      }
    ]
  })
}