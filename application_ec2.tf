# ==============================================================================
# AMI AMAZON LINUX 2023 — x86_64
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
# IAM — ACCÈS À SESSION MANAGER
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

resource "aws_iam_instance_profile" "test_ec2" {
  name = "aws-lab-test-ec2-profile"
  role = aws_iam_role.test_ec2_ssm.name
}

# ==============================================================================
# EC2 PRIVÉE — COUCHE APPLICATION
# ==============================================================================

resource "aws_instance" "application" {
  ami           = data.aws_ami.test_al2023.id
  instance_type = "t3.micro"

  subnet_id                   = module.application_subnets.subnet_ids["private-app"]
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.application.id]
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

  # Prépare les permissions et le chemin réseau avant le démarrage de l'EC2.
  depends_on = [
    aws_iam_role_policy_attachment.test_ec2_ssm,
    aws_vpc_security_group_egress_rule.private_tiers_https["application"],
    aws_route.application_private_to_tgw,
    aws_route.inspection_tgw_to_firewall,
    aws_route.inspection_firewall_to_nat,
    aws_route.inspection_firewall_to_tgw,
    aws_route.inspection_nat_to_internet,
    aws_route.inspection_nat_to_firewall,
  ]

  tags = {
    Name      = "aws-lab-application"
    Project   = "AWS-Cloud-Security-Lab"
    ManagedBy = "Terraform"
  }
}

output "application_ec2_id" {
  description = "ID de l'EC2 Application pour ouvrir une session SSM."
  value       = aws_instance.application.id
}