# ==============================================================================
# NAT GATEWAY — SUBNETS PAR AZ
# Chaque NAT Gateway est placée dans le subnet NAT de sa propre AZ.
# Le routage Firewall → NAT → IGW sera configuré ensuite.
# ==============================================================================

locals {
  inspection_nat_subnets = {
    "eu-west-3a" = module.inspection_subnets.subnet_ids["inspection-nat-a"]
    "eu-west-3b" = module.inspection_subnets.subnet_ids["inspection-nat-b"]
  }
}

# ==============================================================================
# ELASTIC IP — UNE ADRESSE PUBLIQUE PAR NAT GATEWAY
# Ces adresses serviront d'adresses sources publiques pour la sortie Internet.
# ==============================================================================

resource "aws_eip" "inspection_nat" {
  for_each = local.inspection_nat_subnets

  domain = "vpc"

  tags = {
    Name      = "aws-lab-inspection-nat-eip-${each.key}"
    Project   = "AWS-Cloud-Security-Lab"
    ManagedBy = "Terraform"
  }
}

# ==============================================================================
# NAT GATEWAY PUBLIQUES — UNE PAR AZ
# Traduisent les adresses sources privées pour permettre la sortie Internet.
# Chaque NAT utilise son Elastic IP et dépend de l'IGW Inspection.
# Les routes aller et retour restent nécessaires pour assurer la communication.
# ==============================================================================

resource "aws_nat_gateway" "inspection" {
  for_each = local.inspection_nat_subnets

  allocation_id     = aws_eip.inspection_nat[each.key].id
  subnet_id         = each.value
  connectivity_type = "public"

  depends_on = [module.inspection_igw]

  tags = {
    Name      = "aws-lab-inspection-nat-${each.key}"
    Project   = "AWS-Cloud-Security-Lab"
    ManagedBy = "Terraform"
  }
}