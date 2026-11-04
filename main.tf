# ROOT MODULE: Infrastructure composition and explicit inter-VPC routing.
# Read README.md for architecture, current scope, and deployment warnings.

# ==============================================================================
# APPLICATION VPC
# Creates the application network (10.0.0.0/16), with DNS support enabled.
# ==============================================================================
module "application_vpc" {
  source = "./modules/vpc"

  vpc_name = "aws-lab-application-vpc"
  vpc_cidr = "10.0.0.0/16"
}

# ==============================================================================
# APPLICATION SUBNETS
# Defines public ALB, private workload, and Transit Gateway attachment subnets.
# Explicit availability zones keep subnet placement predictable.
# ==============================================================================
module "application_subnets" {
  source = "./modules/subnets"

  vpc_id = module.application_vpc.vpc_id
  subnets = {
    "public-alb-a" = {
      cidr = "10.0.1.0/24"
      az   = "eu-west-3a"
    }

    "public-alb-b" = {
      cidr = "10.0.5.0/24"
      az   = "eu-west-3b"
    }

    "private-web" = {
      cidr = "10.0.2.0/24"
      az   = "eu-west-3a"
    }

    "private-app" = {
      cidr = "10.0.3.0/24"
      az   = "eu-west-3a"
    }

    "private-database-a" = {
      cidr = "10.0.4.0/24"
      az   = "eu-west-3a"
    }

    "private-database-b" = {
      cidr = "10.0.6.0/24"
      az   = "eu-west-3b"
    }

    "application-tgw-a" = {
      cidr = "10.0.10.0/24"
      az   = "eu-west-3a"
    }

    "application-tgw-b" = {
      cidr = "10.0.11.0/24"
      az   = "eu-west-3b"
    }
  }

}

# ==============================================================================
# APPLICATION INTERNET GATEWAY
# Attaches an Internet Gateway to the Application VPC.
# Only subnets using a route to this gateway have direct internet routing.
# ==============================================================================
module "application_igw" {
  source = "./modules/internet_gateway"

  vpc_id   = module.application_vpc.vpc_id
  igw_name = "aws-lab-application-igw"
}

# ==============================================================================
# PUBLIC ROUTING
# Creates a route to the Internet Gateway and associates the public ALB subnets.
# ==============================================================================
module "application_route_tables" {
  source = "./modules/route_tables"

  vpc_id           = module.application_vpc.vpc_id
  igw_id           = module.application_igw.igw_id
  route_table_name = "aws-lab-application-public-rt"

  public_subnet_ids = {
    "public-alb-a" = module.application_subnets.subnet_ids["public-alb-a"]
    "public-alb-b" = module.application_subnets.subnet_ids["public-alb-b"]
  }
}

# ==============================================================================
# PRIVATE WORKLOAD ROUTING
# Creates dedicated route tables for web, application, and database subnets.
# Their default routes are later added separately and point to the Transit Gateway.
# ==============================================================================
module "application_private_routes" {
  source = "./modules/private_route_tables"

  vpc_id = module.application_vpc.vpc_id

  private_subnet_ids = {
    "application-web"  = module.application_subnets.subnet_ids["private-web"]
    "application-app"  = module.application_subnets.subnet_ids["private-app"]
    "application-db"   = module.application_subnets.subnet_ids["private-database-a"]
    "application-db-b" = module.application_subnets.subnet_ids["private-database-b"]
  }
}

# Inspection VPC
# ==============================================================================
# INSPECTION VPC
# Creates a separate VPC (10.1.0.0/16) intended to host security appliances.
# ==============================================================================
module "inspection_vpc" {
  source = "./modules/vpc"

  vpc_name = "aws-lab-inspection-vpc"
  vpc_cidr = "10.1.0.0/16"
}

# ==============================================================================
# INSPECTION SUBNETS
# Reserves separate per-AZ subnets for TGW attachments, firewall endpoints, and NAT.
# Creating these subnets does not create the firewall or NAT gateways.
# ==============================================================================
module "inspection_subnets" {
  source = "./modules/subnets"

  vpc_id = module.inspection_vpc.vpc_id

  subnets = {
    "inspection-tgw-a" = {
      cidr = "10.1.1.0/24"
      az   = "eu-west-3a"
    }

    "inspection-firewall-a" = {
      cidr = "10.1.2.0/24"
      az   = "eu-west-3a"
    }

    "inspection-nat-a" = {
      cidr = "10.1.3.0/24"
      az   = "eu-west-3a"
    }

    "inspection-tgw-b" = {
      cidr = "10.1.11.0/24"
      az   = "eu-west-3b"
    }

    "inspection-firewall-b" = {
      cidr = "10.1.12.0/24"
      az   = "eu-west-3b"
    }

    "inspection-nat-b" = {
      cidr = "10.1.13.0/24"
      az   = "eu-west-3b"
    }
  }
}

# ==============================================================================
# CENTRAL TRANSIT GATEWAY
# Creates the Transit Gateway that interconnects the VPCs.
# ==============================================================================
module "central_tgw" {
  source = "./modules/transit_gateway"
}

# ==============================================================================
# APPLICATION VPC ATTACHMENT
# Attaches the Application VPC to the central TGW. Appliance mode is disabled.
# ==============================================================================
module "application_tgw_attachment" {
  source = "./modules/tgw_attachment"

  tgw_id = module.central_tgw.tgw_id
  vpc_id = module.application_vpc.vpc_id

  subnet_ids = [
    module.application_subnets.subnet_ids["application-tgw-a"],
    module.application_subnets.subnet_ids["application-tgw-b"]
  ]

  appliance_mode  = "disable"
  attachment_name = "aws-lab-application-tgw-attachment"
  depends_on      = [aws_iam_service_linked_role.transit_gateway]
}

# ==============================================================================
# TRANSIT GATEWAY SERVICE ROLE
# Creates the AWS service-linked role required by this configuration.
# The role may already exist in another deployment within the account.
# ==============================================================================
resource "aws_iam_service_linked_role" "transit_gateway" {
  aws_service_name = "transitgateway.amazonaws.com"
}

# ==============================================================================
# INSPECTION VPC ATTACHMENT
# Attaches the Inspection VPC to the TGW with appliance mode enabled.
# Appliance mode helps maintain AZ affinity for stateful inspection paths; it does not create inspection itself.
# ==============================================================================
module "inspection_tgw_attachment" {
  source = "./modules/tgw_attachment"

  tgw_id = module.central_tgw.tgw_id
  vpc_id = module.inspection_vpc.vpc_id

  subnet_ids = [
    module.inspection_subnets.subnet_ids["inspection-tgw-a"],
    module.inspection_subnets.subnet_ids["inspection-tgw-b"]
  ]

  appliance_mode  = "enable"
  attachment_name = "aws-lab-inspection-tgw-attachment"

  depends_on = [
    aws_iam_service_linked_role.transit_gateway
  ]
}

# ==============================================================================
# TGW ROUTE TABLE: APPLICATION
# Dedicated TGW routing domain for traffic arriving from the Application VPC.
# ==============================================================================
resource "aws_ec2_transit_gateway_route_table" "application" {
  transit_gateway_id = module.central_tgw.tgw_id

  tags = {
    Name      = "aws-lab-tgw-rt-application"
    Project   = "AWS-Cloud-Security-Lab"
    ManagedBy = "Terraform"
  }
}

# ==============================================================================
# TGW ROUTE TABLE: INSPECTION
# Dedicated TGW routing domain for traffic arriving from the Inspection VPC.
# ==============================================================================
resource "aws_ec2_transit_gateway_route_table" "inspection" {
  transit_gateway_id = module.central_tgw.tgw_id

  tags = {
    Name      = "aws-lab-tgw-rt-inspection"
    Project   = "AWS-Cloud-Security-Lab"
    ManagedBy = "Terraform"
  }
}

# ==============================================================================
# ASSOCIATE APPLICATION ATTACHMENT
# Associates the Application VPC attachment with its dedicated TGW route table.
# ==============================================================================
resource "aws_ec2_transit_gateway_route_table_association" "application" {
  transit_gateway_attachment_id  = module.application_tgw_attachment.attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.application.id
}

# ==============================================================================
# ASSOCIATE INSPECTION ATTACHMENT
# Associates the Inspection VPC attachment with its dedicated TGW route table.
# ==============================================================================
resource "aws_ec2_transit_gateway_route_table_association" "inspection" {
  transit_gateway_attachment_id  = module.inspection_tgw_attachment.attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection.id
}

# Aller : envoyer le trafic vers le VPC Inspection
# ==============================================================================
# FORWARD ROUTE: APPLICATION TO INSPECTION
# Sends non-local destinations (0.0.0.0/0) arriving on the Application TGW route table
# to the Inspection VPC attachment. Further VPC routing is still required.
# ==============================================================================
resource "aws_ec2_transit_gateway_route" "application_to_inspection" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.application.id
  transit_gateway_attachment_id  = module.inspection_tgw_attachment.attachment_id
}

# Retour : rejoindre le VPC Application
# ==============================================================================
# RETURN ROUTE: INSPECTION TO APPLICATION
# Sends 10.0.0.0/16 traffic arriving on the Inspection TGW route table
# back through the Application VPC attachment.
# ==============================================================================
resource "aws_ec2_transit_gateway_route" "inspection_to_application" {
  destination_cidr_block         = "10.0.0.0/16"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection.id
  transit_gateway_attachment_id  = module.application_tgw_attachment.attachment_id
}

# ==============================================================================
# APPLICATION SUBNET DEFAULT ROUTES
# Adds 0.0.0.0/0 -> TGW to every private workload route table.
# for_each creates one route per route table exposed by the module.
# ==============================================================================
resource "aws_route" "application_private_to_tgw" {
  for_each = module.application_private_routes.route_table_ids

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.central_tgw.tgw_id

  depends_on = [module.application_tgw_attachment]
}

# ==============================================================================
# INTERNET GATEWAY — VPC INSPECTION
# Attache un Internet Gateway au VPC Inspection.
# Il permettra la sortie Internet après le Firewall et les NAT Gateway.
# Les routes vers cet IGW seront configurées dans les tables des subnets NAT.
# Ce bloc seul ne fournit pas encore un accès Internet.
# ==============================================================================

module "inspection_igw" {
  source = "./modules/internet_gateway"

  vpc_id   = module.inspection_vpc.vpc_id
  igw_name = "aws-lab-inspection-igw"
}