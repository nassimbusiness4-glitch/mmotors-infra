# ============ d. VM de dev (EC2 Spot) ============

# dernière image Amazon Linux 2023 (pas d'ID en dur qui vieillit)
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# on envoie seulement la clé PUBLIQUE, la privée reste sur le PC
resource "aws_key_pair" "dev" {
  key_name   = "${var.project}-dev-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

# pare-feu : SSH uniquement depuis mon IP
resource "aws_security_group" "ec2_dev" {
  name        = "${var.project}-ec2-dev-sg"
  description = "SSH depuis mon IP uniquement"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # la VM peut sortir (mises à jour, connexion à la base)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "dev" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.ec2_dev.id]
  key_name               = aws_key_pair.dev.key_name

  # Spot (imposé) + persistante + "stop" -> on peut l'éteindre la nuit sans la perdre
  instance_market_options {
    market_type = "spot"
    spot_options {
      spot_instance_type             = "persistent"
      instance_interruption_behavior = "stop"
    }
  }

  # disque chiffré
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  # installe le client PostgreSQL au démarrage (pour la démo de migration)
  user_data = <<-EOF
    #!/bin/bash
    dnf install -y postgresql16
  EOF

  tags = { Name = "${var.project}-dev" }
}