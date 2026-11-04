# Regroupe les deux subnets privés dans lesquels RDS pourra placer PostgreSQL.
resource "aws_db_subnet_group" "database" {
  name        = "aws-lab-database"
  description = "Private database subnets in eu-west-3a and eu-west-3b"

  subnet_ids = [
    module.application_subnets.subnet_ids["private-database-a"],
    module.application_subnets.subnet_ids["private-database-b"],
  ]
}

resource "aws_db_instance" "database" {
  identifier     = "aws-lab-postgres"
  engine         = "postgres"
  instance_class = "db.t3.micro"

  db_name = "awslab"
  port    = 5432

  # RDS génère et stocke le mot de passe administrateur dans Secrets Manager.
  username                    = "labadmin"
  manage_master_user_password = true

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_subnet_group_name   = aws_db_subnet_group.database.name
  vpc_security_group_ids = [aws_security_group.database.id]
  publicly_accessible    = false
  multi_az               = false

  # Pour ce lab jetable, la suppression ne crée pas de snapshot final.
  skip_final_snapshot = true

  tags = {
    Name      = "aws-lab-postgres"
    Project   = "AWS-Cloud-Security-Lab"
    ManagedBy = "Terraform"
  }
}