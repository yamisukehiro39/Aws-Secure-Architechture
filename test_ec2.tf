# ==============================================================================
# IMAGE AMAZON LINUX 2023
# Recherche une AMI officielle Amazon Linux 2023 pour processeur x86_64.
# ==============================================================================

data "aws_ami" "test_al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# ==============================================================================
# ROLE IAM POUR SSM
# Autorise EC2 à assumer ce rôle.
# La policy attachée fournit les permissions nécessaires à l'agent SSM.
# ==============================================================================

resource "aws_iam_role" "test_ec2_ssm" {
  name = "aws-lab-test-ec2-ssm"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "test_ec2_ssm" {
  role       = aws_iam_role.test_ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Le profil d'instance permet d'attacher le rôle IAM à l'EC2.
resource "aws_iam_instance_profile" "test_ec2" {
  name = "aws-lab-test-ec2-profile"
  role = aws_iam_role.test_ec2_ssm.name
}

# ==============================================================================
# SECURITY GROUP DE TEST
# Aucune connexion entrante autorisée : pas de port SSH ouvert.
# Autorise les connexions sortantes TCP/443 et leurs réponses.
# La résolution DNS utilisera le résolveur Amazon du VPC.
# ==============================================================================

resource "aws_security_group" "test_ec2" {
  name        = "aws-lab-test-ec2-sg"
  description = "Private test instance - outbound TCP 443"
  vpc_id      = module.application_vpc.vpc_id

  egress {
    description = "Outbound TCP 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "aws-lab-test-ec2-sg"
    Project   = "AWS-Cloud-Security-Lab"
    ManagedBy = "Terraform"
  }
}

# ==============================================================================
# INSTANCE EC2 PRIVEE DE TEST
# Placée dans private-web, en eu-west-3a.
# Utilise le routage existant : TGW → Firewall → NAT → IGW.
# Active l'agent SSM sans installer de paquets supplémentaires.
# ==============================================================================

resource "aws_instance" "test" {
  ami           = data.aws_ami.test_al2023.id
  instance_type = "t3.micro"

  subnet_id                   = module.application_subnets.subnet_ids["private-web"]
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.test_ec2.id]
  iam_instance_profile        = aws_iam_instance_profile.test_ec2.name

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size           = 8
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-EOF
    #!/bin/bash
    systemctl enable --now amazon-ssm-agent
  EOF

  depends_on = [
    aws_iam_role_policy_attachment.test_ec2_ssm,
    aws_route.application_private_to_tgw,
    aws_route.inspection_tgw_to_firewall,
    aws_route.inspection_firewall_to_nat,
    aws_route.inspection_firewall_to_tgw,
    aws_route.inspection_nat_to_internet,
    aws_route.inspection_nat_to_firewall
  ]

  tags = {
    Name      = "aws-lab-private-test"
    Project   = "AWS-Cloud-Security-Lab"
    ManagedBy = "Terraform"
  }
}

# Identifiants utiles pour la connexion et les tests.
output "test_ec2_id" {
  value = aws_instance.test.id
}

output "test_ec2_private_ip" {
  value = aws_instance.test.private_ip
}