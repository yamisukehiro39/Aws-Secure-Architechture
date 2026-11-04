# ==============================================================================
# ROUTAGE INSPECTION — SUBNETS TGW VERS FIREWALL
# Crée une table de routage par subnet TGW du VPC Inspection.
# Chaque table envoie les destinations externes vers l'endpoint Firewall
# de sa propre AZ pour imposer le passage par l'inspection.
# Les identifiants des endpoints sont récupérés automatiquement.
# ==============================================================================

locals {
  inspection_tgw_subnets = {
    "eu-west-3a" = module.inspection_subnets.subnet_ids["inspection-tgw-a"]
    "eu-west-3b" = module.inspection_subnets.subnet_ids["inspection-tgw-b"]
  }

  firewall_endpoints = {
    for state in aws_networkfirewall_firewall.inspection.firewall_status[0].sync_states :
    state.availability_zone => state.attachment[0].endpoint_id
  }
}

# Une table par AZ.
resource "aws_route_table" "inspection_tgw" {
  for_each = local.inspection_tgw_subnets

  vpc_id = module.inspection_vpc.vpc_id

  tags = {
    Name      = "aws-lab-inspection-tgw-rt-${each.key}"
    Project   = "AWS-Cloud-Security-Lab"
    ManagedBy = "Terraform"
  }
}

# Associe chaque subnet TGW à sa table.
resource "aws_route_table_association" "inspection_tgw" {
  for_each = local.inspection_tgw_subnets

  subnet_id      = each.value
  route_table_id = aws_route_table.inspection_tgw[each.key].id
}

# Envoie le trafic vers l'endpoint Firewall de la même AZ.
resource "aws_route" "inspection_tgw_to_firewall" {
  for_each = local.inspection_tgw_subnets

  route_table_id         = aws_route_table.inspection_tgw[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = local.firewall_endpoints[each.key]
}

# ==============================================================================
# TABLES DE ROUTAGE DES SUBNETS NAT — UNE PAR AZ
# Chaque subnet NAT possède sa propre table pour utiliser
# l'endpoint Firewall de sa zone sur le chemin retour.
# ==============================================================================

resource "aws_route_table" "inspection_nat" {
  for_each = local.inspection_nat_subnets

  vpc_id = module.inspection_vpc.vpc_id

  tags = {
    Name      = "aws-lab-inspection-nat-rt-${each.key}"
    Project   = "AWS-Cloud-Security-Lab"
    ManagedBy = "Terraform"
  }
}

# Associe chaque subnet NAT à sa table.
resource "aws_route_table_association" "inspection_nat" {
  for_each = local.inspection_nat_subnets

  subnet_id      = each.value
  route_table_id = aws_route_table.inspection_nat[each.key].id
}

# ==============================================================================
# SORTIE INTERNET — NAT VERS IGW
# Les destinations externes sont acheminées vers l'IGW Inspection.
# ==============================================================================

resource "aws_route" "inspection_nat_to_internet" {
  for_each = local.inspection_nat_subnets

  route_table_id         = aws_route_table.inspection_nat[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = module.inspection_igw.igw_id
}

# ==============================================================================
# RETOUR VERS APPLICATION — NAT VERS FIREWALL
# Après traduction retour par la NAT, les réponses destinées au
# VPC Application sont dirigées vers le Firewall de la même AZ.
# Cette route empêche un retour direct vers le TGW sans inspection.
# ==============================================================================

resource "aws_route" "inspection_nat_to_firewall" {
  for_each = local.inspection_nat_subnets

  route_table_id         = aws_route_table.inspection_nat[each.key].id
  destination_cidr_block = module.application_vpc.vpc_cidr
  vpc_endpoint_id        = local.firewall_endpoints[each.key]
}

# ==============================================================================
# SUBNETS FIREWALL — IDENTIFICATION PAR AZ
# Permet d'associer chaque subnet Firewall à une table dédiée.
# ==============================================================================

locals {
  inspection_firewall_subnets = {
    "eu-west-3a" = module.inspection_subnets.subnet_ids["inspection-firewall-a"]
    "eu-west-3b" = module.inspection_subnets.subnet_ids["inspection-firewall-b"]
  }
}

# ==============================================================================
# TABLES DE ROUTAGE FIREWALL — UNE PAR AZ
# Après inspection, ces tables dirigent le trafic vers la NAT à l'aller
# et vers le TGW au retour.
# ==============================================================================

resource "aws_route_table" "inspection_firewall" {
  for_each = local.inspection_firewall_subnets

  vpc_id = module.inspection_vpc.vpc_id

  tags = {
    Name      = "aws-lab-inspection-firewall-rt-${each.key}"
    Project   = "AWS-Cloud-Security-Lab"
    ManagedBy = "Terraform"
  }
}

# Associe chaque subnet Firewall à sa table.
resource "aws_route_table_association" "inspection_firewall" {
  for_each = local.inspection_firewall_subnets

  subnet_id      = each.value
  route_table_id = aws_route_table.inspection_firewall[each.key].id
}

# ==============================================================================
# ALLER — FIREWALL VERS NAT
# Envoie les destinations externes vers la NAT Gateway de la même AZ.
# ==============================================================================

resource "aws_route" "inspection_firewall_to_nat" {
  for_each = local.inspection_firewall_subnets

  route_table_id         = aws_route_table.inspection_firewall[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.inspection[each.key].id
}

# ==============================================================================
# RETOUR — FIREWALL VERS TGW
# Renvoie les paquets destinés au VPC Application vers le TGW.
# La route /16 est plus spécifique que la route par défaut vers la NAT.
# ==============================================================================

resource "aws_route" "inspection_firewall_to_tgw" {
  for_each = local.inspection_firewall_subnets

  route_table_id         = aws_route_table.inspection_firewall[each.key].id
  destination_cidr_block = "10.0.0.0/16"
  transit_gateway_id     = module.central_tgw.tgw_id

  depends_on = [module.inspection_tgw_attachment]
}