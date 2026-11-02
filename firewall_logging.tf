# ==============================================================================
# CLOUDWATCH LOG GROUPS — LOGS DU FIREWALL
# FLOW : informations sur les flux observés par le moteur stateful.
# ALERT : événements produits par les règles/actions générant des alertes.
# Conservation limitée à 7 jours pour le lab.
# ==============================================================================

resource "aws_cloudwatch_log_group" "firewall" {
  for_each = toset(["FLOW", "ALERT"])

  name              = "/aws/network-firewall/inspection/${lower(each.key)}"
  retention_in_days = 7

  tags = {
    Project   = "AWS-Cloud-Security-Lab"
    ManagedBy = "Terraform"
  }
}

# ==============================================================================
# ACTIVATION DE LA LIVRAISON DES LOGS
# Associe chaque type de logs à son groupe CloudWatch.
# Cette configuration ne modifie ni les routes ni les règles de filtrage.
# Activer ALERT ne crée pas automatiquement une alerte pour chaque paquet.
# ==============================================================================

resource "aws_networkfirewall_logging_configuration" "inspection" {
  firewall_arn = aws_networkfirewall_firewall.inspection.arn

  logging_configuration {
    dynamic "log_destination_config" {
      for_each = aws_cloudwatch_log_group.firewall

      content {
        log_destination = {
          logGroup = log_destination_config.value.name
        }

        log_destination_type = "CloudWatchLogs"
        log_type             = log_destination_config.key
      }
    }
  }
}