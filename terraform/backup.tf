##########################
# AWS Backup Vault
##########################
resource "aws_backup_vault" "luxe_vault" {
  name = "luxe-backup-vault"
  tags = {
    Project = "LuxeJewelry"
  }
}

##########################
# AWS Backup Plan
##########################
resource "aws_backup_plan" "luxe_plan" {
  name = "luxe-daily-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.luxe_vault.name
    # Schedule: Runs daily at 12:00 UTC
    schedule          = "cron(0 12 * * ? *)" 
    
    lifecycle {
      # FinOps: Delete backups after 7 days to save storage costs
      delete_after = 7 
    }
  }
}

##########################
# Backup Selection (Targeting)
##########################
resource "aws_backup_selection" "luxe_selection" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "luxe-ec2-selection"
  plan_id      = aws_backup_plan.luxe_plan.id

  # This targets the runner we created in runners.tf via the Tag
  selection_tag {
    type  = "STRINGEQUALS"
    key   = "Backup"
    value = "True"
  }
}

##########################
# IAM Role for Backup
##########################
resource "aws_iam_role" "backup_role" {
  name = "luxe-backup-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy_attach" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}