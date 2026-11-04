# ==============================================================================
# ADRESSE AUTORISEE A ACCEDER A L'APPLICATION
# Adresse IPv4 publique du poste utilisé pour les tests, au format CIDR /32.
# Cette variable permettra de limiter l'entrée de l'ALB à cette seule adresse.
# Elle ne crée aucune règle réseau à elle seule.
# ==============================================================================

variable "allowed_client_cidr" {
  description = "Adresse IPv4 publique autorisée à accéder à l'ALB."
  type        = string
}