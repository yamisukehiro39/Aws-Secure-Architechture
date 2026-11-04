# ==============================================================================
# SECURITY GROUP DE L'ALB
# Placé dans le VPC Application.
# Les règles sont déclarées séparément.
# Ce bloc crée uniquement le groupe, pas encore l'ALB.
# ==============================================================================

resource "aws_security_group" "alb" {
  name        = "aws-lab-alb-sg"
  description = "Public ALB - restricted client access"
  vpc_id      = module.application_vpc.vpc_id

  tags = {
    Name      = "aws-lab-alb-sg"
    Project   = "AWS-Cloud-Security-Lab"
    ManagedBy = "Terraform"
  }
}

# ==============================================================================
# TON POSTE VERS L'ALB — HTTP
# Autorise TCP/80 depuis ton IP publique uniquement.
# L'adresse est fournie par allowed_client_cidr dans terraform.tfvars.
# La sortie vers la couche Web sera ajoutée ensuite.
# ==============================================================================

resource "aws_vpc_security_group_ingress_rule" "client_to_alb" {
  security_group_id = aws_security_group.alb.id

  description = "HTTP from authorized client"
  cidr_ipv4   = var.allowed_client_cidr
  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
}

# ==============================================================================
# SECURITY GROUP DE LA COUCHE WEB
# Destiné à l'instance Nginx dans le subnet private-web.
# L'entrée HTTP sera autorisée uniquement depuis le Security Group de l'ALB.
# Ce bloc ne crée pas encore l'instance Web.
# ==============================================================================

resource "aws_security_group" "web" {
  name        = "aws-lab-web-sg"
  description = "Private web tier"
  vpc_id      = module.application_vpc.vpc_id

  tags = {
    Name      = "aws-lab-web-sg"
    Project   = "AWS-Cloud-Security-Lab"
    ManagedBy = "Terraform"
  }
}

# ==============================================================================
# SORTIE ALB VERS WEB — TCP/80
# Autorise l'ALB à joindre les instances portant le Security Group Web.
# Cette connexion servira aux requêtes HTTP et aux health checks.
# ==============================================================================

resource "aws_vpc_security_group_egress_rule" "alb_to_web" {
  security_group_id = aws_security_group.alb.id

  description                  = "HTTP to web tier"
  referenced_security_group_id = aws_security_group.web.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}

# ==============================================================================
# ENTREE WEB DEPUIS L'ALB — TCP/80
# Accepte les connexions HTTP provenant des interfaces portant le groupe ALB.
# Aucune entrée depuis Internet ou depuis tout le VPC n'est ouverte.
# ==============================================================================

resource "aws_vpc_security_group_ingress_rule" "web_from_alb" {
  security_group_id = aws_security_group.web.id

  description                  = "HTTP from ALB"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = 80
  to_port                      = 80
}

# ==============================================================================
# SECURITY GROUP DE LA COUCHE APPLICATION                                      #
# Destiné à l'EC2 qui hébergera notre API Python dans private-app.             #
# L'entrée sur TCP/8000 sera limitée au Security Group Web.                    #
# Ce bloc ne crée pas encore l'instance Application.                           #
# ============================================================================== 

resource "aws_security_group" "application" {
  name        = "aws-lab-application-sg"
  description = "Private application tier"
  vpc_id      = module.application_vpc.vpc_id

  tags = {
    Name      = "aws-lab-application-sg"
    Project   = "AWS-Cloud-Security-Lab"
    ManagedBy = "Terraform"
  }
}

# ==============================================================================
# SORTIE WEB VERS APPLICATION — TCP/8000
# Autorise Nginx à joindre l'API sur les interfaces portant le groupe Application.
# ==============================================================================

resource "aws_vpc_security_group_egress_rule" "web_to_application" {
  security_group_id = aws_security_group.web.id

  description                  = "API requests from web tier"
  referenced_security_group_id = aws_security_group.application.id
  ip_protocol                  = "tcp"
  from_port                    = 8000
  to_port                      = 8000
}

# ==============================================================================
# ENTREE APPLICATION DEPUIS WEB — TCP/8000
# Accepte les connexions à l'API uniquement depuis le Security Group Web.
# Le groupe ALB et les autres instances ne sont pas autorisés par cette règle.
# ==============================================================================

resource "aws_vpc_security_group_ingress_rule" "application_from_web" {
  security_group_id = aws_security_group.application.id

  description                  = "API requests from web tier"
  referenced_security_group_id = aws_security_group.web.id
  ip_protocol                  = "tcp"
  from_port                    = 8000
  to_port                      = 8000
}

# ==============================================================================
# COUCHE DATABASE — POSTGRESQL
# Seules les interfaces portant le groupe Application pourront ouvrir
# une connexion vers la base sur TCP/5432.
# ==============================================================================

resource "aws_security_group" "database" {
  name        = "aws-lab-database-sg"
  description = "Private PostgreSQL tier"
  vpc_id      = module.application_vpc.vpc_id

  tags = {
    Name      = "aws-lab-database-sg"
    Project   = "AWS-Cloud-Security-Lab"
    ManagedBy = "Terraform"
  }
}

# Autorise la sortie de l'API vers PostgreSQL.
resource "aws_vpc_security_group_egress_rule" "application_to_database" {
  security_group_id            = aws_security_group.application.id
  referenced_security_group_id = aws_security_group.database.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

# Autorise l'entrée PostgreSQL depuis le groupe Application.
resource "aws_vpc_security_group_ingress_rule" "database_from_application" {
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = aws_security_group.application.id
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
}

# Une règle de sortie TCP/443 par groupe privé pour SSM et les dépôts HTTPS.
resource "aws_vpc_security_group_egress_rule" "private_tiers_https" {
  for_each = {
    web         = aws_security_group.web.id
    application = aws_security_group.application.id
    database    = aws_security_group.database.id
  }

  security_group_id = each.value
  description       = "HTTPS outbound for SSM and package downloads"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}