# ==============================================================================
# GROUPE DE REGLES STATEFUL — TRAFIC SORTANT
# Autorise les connexions TCP depuis le VPC Application vers le port 443.
# Le port 443 est généralement utilisé par HTTPS.
# Cette règle filtre les adresses et le port, sans vérifier le domaine,
# sans déchiffrer TLS et sans analyser le contenu HTTPS.
# ==============================================================================

resource "aws_networkfirewall_rule_group" "egress" {
  name = "aws-lab-egress-rules"

  # Capacité réservée au groupe de règles.
  # Ce nombre ne représente pas un nombre de connexions autorisées.
  capacity = 100

  # Le moteur stateful suit les connexions et leurs paquets de réponse.
  type = "STATEFUL"

  rule_group {
    stateful_rule_options {
      # Utilise le même ordre d'évaluation que la policy.
      rule_order = "STRICT_ORDER"
    }

    rules_source {
      # Règle au format Suricata :
      # pass          : autoriser la connexion correspondante.
      # tcp           : protocole inspecté.
      # 10.0.0.0/16   : adresses sources du VPC Application.
      # any           : n'importe quel port source.
      # ->            : direction de la connexion initiale.
      # any 443       : n'importe quelle destination sur TCP/443.
      # msg           : description de la règle.
      # sid           : identifiant unique de la règle dans notre configuration.
      # rev           : numéro de révision de la règle.
      #
      # Une action pass autorise le flux correspondant ; elle ne signifie pas
      # que son contenu a été vérifié comme étant sûr.
      rules_string = <<-RULES
        drop tcp 10.0.0.0/16 any -> 142.251.150.119 443 (msg:"LAB Block Google test IP"; sid:1000002; rev:1;)
        pass tcp 10.0.0.0/16 any -> any 443 (msg:"Allow outbound TCP 443"; sid:1000001; rev:1;)
      RULES
    }
  }

  tags = {
    Project   = "AWS-Cloud-Security-Lab"
    ManagedBy = "Terraform"
  }
}

# ==============================================================================
# POLITIQUE AWS NETWORK FIREWALL — VPC INSPECTION
# Transmet les paquets au moteur stateful pour inspecter les connexions.
# Les règles sont évaluées dans l'ordre défini avec STRICT_ORDER.
# Référence le groupe de règles autorisant les connexions sortantes TCP/443.
# Par défaut, bloque le trafic établi qui ne correspond à aucune autorisation.
# Cette configuration crée la policy et son groupe de règles.
# Le Firewall, ses endpoints et les routes de steering seront ajoutés ensuite.
# ==============================================================================

resource "aws_networkfirewall_firewall_policy" "inspection" {
  name = "aws-lab-inspection-policy"

  firewall_policy {
    # Aucun groupe stateless n'est défini ici.
    # Les paquets sont donc transmis au moteur stateful.
    stateless_default_actions = ["aws:forward_to_sfe"]

    # Transmet également les fragments au moteur stateful.
    stateless_fragment_default_actions = [
      "aws:forward_to_sfe"
    ]

    stateful_engine_options {
      # Permet de contrôler explicitement l'ordre des règles et des groupes.
      rule_order = "STRICT_ORDER"
    }

    # Autorise les échanges initiaux nécessaires à l'établissement TCP,
    # puis bloque le trafic établi sans règle d'autorisation correspondante.
    # Pour UDP et ICMP, l'établissement est déterminé après observation
    # du trafic dans les deux directions : ce n'est pas un blocage immédiat
    # de chaque premier paquet non autorisé.
    stateful_default_actions = ["aws:drop_established"]

    # Attache le groupe de règles à cette policy.
    stateful_rule_group_reference {
      # Les groupes de plus faible valeur sont évalués en premier.
      priority = 10

      resource_arn = aws_networkfirewall_rule_group.egress.arn
    }
  }

  tags = {
    Project   = "AWS-Cloud-Security-Lab"
    ManagedBy = "Terraform"
  }
}


# ==============================================================================
# AWS NETWORK FIREWALL — VPC INSPECTION
# Déploie le Firewall et lui applique notre policy.
# Crée un endpoint dans chaque subnet Firewall : AZ-a et AZ-b.
# Ces endpoints serviront de cibles dans les tables de routage Inspection.
# Les routes de traffic steering seront ajoutées à l'étape suivante.
# ==============================================================================

resource "aws_networkfirewall_firewall" "inspection" {
  name = "aws-lab-inspection-firewall"

  vpc_id = module.inspection_vpc.vpc_id

  firewall_policy_arn = aws_networkfirewall_firewall_policy.inspection.arn

  subnet_mapping {
    subnet_id = module.inspection_subnets.subnet_ids["inspection-firewall-a"]
  }

  subnet_mapping {
    subnet_id = module.inspection_subnets.subnet_ids["inspection-firewall-b"]
  }

  # Facilite la suppression des ressources à la fin du lab.
  delete_protection = false

  tags = {
    Project   = "AWS-Cloud-Security-Lab"
    ManagedBy = "Terraform"
  }
}