# pare-feu de l'ALB : ouvert sur le port 80
resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg"
  description = "HTTP depuis internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# le load balancer, dans les subnets publics
resource "aws_lb" "main" {
  name               = "${var.project}-alb"
  load_balancer_type = "application"
  subnets            = aws_subnet.public[*].id
  security_groups    = [aws_security_group.alb.id]
}

# les conteneurs vers qui envoyer le trafic
resource "aws_lb_target_group" "app" {
  name        = "${var.project}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip" # obligatoire avec Fargate

  # l'ALB vérifie que le conteneur répond
  health_check {
    path    = "/"
    matcher = "200"
  }
}

# ce qui arrive sur le port 80 part vers les conteneurs
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}