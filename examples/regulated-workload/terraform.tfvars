# Regulated Workload Example — Strict controls for regulated industries
#
# Use case: Financial services, healthcare, or other regulated workloads
# requiring strict control over regions, encryption, MFA, and auditability.
#
# Assumes you have a dedicated Security Tooling account for central
# GuardDuty, SecurityHub, Config, and CloudTrail management.
#
# What this sets up:
#   Root
#   ├── Regulated
#   │   ├── Production
#   │   └── UAT
#   └── Non-Regulated
#       └── Development
#
# Key differences from standard:
# - Region-locked via SCP (only us-east-1 and us-west-2)
# - Root user restrictions enforced via CT controls
# - MFA required
# - Full encryption enforced (EBS, RDS)
# - All logging controls enabled
# - RCP: require SSL + confused-deputy protection (blocks external principals)
# - Backup: daily + weekly with cross-region DR copy for BackupTier=critical
# - AI opt-out: prevent AWS from using content for AI/ML training (HIPAA/PCI)

tags = {
  Project    = "org-governance"
  ManagedBy  = "Terraform"
  Compliance = "Regulated"
}

organization = {
  units = [
    {
      name        = "Regulated"
      key         = "regulated"
      ct_register = true
      units = [
        { name = "Production", key = "regulated/production", ct_register = true },
        { name = "UAT", key = "regulated/uat", ct_register = true },
      ]
    },
    {
      name        = "Non-Regulated"
      key         = "non-regulated"
      ct_register = true
      units = [
        { name = "Development", key = "non-regulated/development", ct_register = true },
      ]
    },
  ]
}

scp_policies = {
  "scp-foundation-guardrails" = {
    description = "Foundation: deny org leave, IMDSv2, encryption, RAM external sharing"
    path        = "policies/scp/scp-foundation-guardrails.json.tpl"
    vars        = { breakglass_role = "BreakGlass-Admin" }
    targets     = ["regulated", "non-regulated"]
  }
}

rcp_policies = {
  "rcp-require-ssl" = {
    description = "Require SSL for S3, SQS, Secrets Manager — enforces even cross-account access"
    path        = "policies/rcp/rcp-require-ssl.json"
    vars        = {}
    targets     = ["regulated"]
  }
  "rcp-confused-deputy-protection" = {
    description = "Block external principals and enforce aws:SourceAccount for service principals"
    path        = "policies/rcp/rcp-enforce-confused-deputy-protection.json.tpl"
    vars        = {}
    targets     = ["regulated"]
  }
}

backup_policies = {
  "backup-critical-daily-weekly" = {
    description = "Daily + weekly backups with DR copy for BackupTier=critical resources"
    path        = "policies/backup/backup-policy-critical-daily-weekly.json.tpl"
    vars = {
      primary_region = "us-east-1"
      dr_region      = "us-west-2"
      vault_name     = "RegulatedBackupVault"
      dr_vault_name  = "RegulatedDRBackupVault"
    }
    targets = ["regulated"]
  }
}

ai_opt_out_policies = {
  "ai-opt-out-all" = {
    description = "Opt out of AWS using regulated content for AI/ML service improvement"
    path        = "policies/ai-opt-out/ai-opt-out-all.json"
    targets     = ["root"]
  }
}

ct_baseline_version             = "5.0"
ct_identity_center_baseline_arn = ""
enable_ram_sharing              = false

# Comprehensive controls — regulated workloads should have all of these
ct_controls = [
  # Encryption — mandatory for regulated data
  { control = "AWS-GR_ENCRYPTED_VOLUMES", target = "regulated" },
  { control = "AWS-GR_RDS_STORAGE_ENCRYPTED", target = "regulated" },
  { control = "AWS-GR_AUDIT_BUCKET_ENCRYPTION_ENABLED", target = "regulated" },

  # Network isolation
  { control = "AWS-GR_EC2_INSTANCE_NO_PUBLIC_IP", target = "regulated" },
  { control = "AWS-GR_SUBNET_AUTO_ASSIGN_PUBLIC_IP_DISABLED", target = "regulated" },
  { control = "AWS-GR_RESTRICTED_SSH", target = "regulated" },
  { control = "AWS-GR_RESTRICTED_COMMON_PORTS", target = "regulated" },
  { control = "AWS-GR_RDS_INSTANCE_PUBLIC_ACCESS_CHECK", target = "regulated" },

  # Data protection
  { control = "AWS-GR_S3_BUCKET_PUBLIC_READ_PROHIBITED", target = "regulated" },
  { control = "AWS-GR_S3_BUCKET_PUBLIC_WRITE_PROHIBITED", target = "regulated" },
  { control = "AWS-GR_S3_VERSIONING_ENABLED", target = "regulated" },
  { control = "AWS-GR_RDS_SNAPSHOTS_PUBLIC_PROHIBITED", target = "regulated" },
  { control = "AWS-GR_EBS_SNAPSHOT_PUBLIC_RESTORABLE_CHECK", target = "regulated" },

  # Identity
  { control = "AWS-GR_RESTRICT_ROOT_USER", target = "regulated" },
  { control = "AWS-GR_RESTRICT_ROOT_USER_ACCESS_KEYS", target = "regulated" },
  { control = "AWS-GR_ROOT_ACCOUNT_MFA_ENABLED", target = "regulated" },
  { control = "AWS-GR_IAM_USER_MFA_ENABLED", target = "regulated" },
  { control = "AWS-GR_MFA_ENABLED_FOR_IAM_CONSOLE_ACCESS", target = "regulated" },

  # Audit trail integrity
  { control = "AWS-GR_CLOUDTRAIL_ENABLED", target = "regulated" },
  { control = "AWS-GR_CLOUDTRAIL_VALIDATION_ENABLED", target = "regulated" },
  { control = "AWS-GR_CLOUDTRAIL_CHANGE_PROHIBITED", target = "regulated" },
  { control = "AWS-GR_CLOUDTRAIL_CLOUDWATCH_LOGS_ENABLED", target = "regulated" },
  { control = "AWS-GR_AUDIT_BUCKET_DELETION_PROHIBITED", target = "regulated" },

  # Config
  { control = "AWS-GR_CONFIG_ENABLED", target = "regulated" },
  { control = "AWS-GR_CONFIG_CHANGE_PROHIBITED", target = "regulated" },
  { control = "AWS-GR_CONFIG_RULE_CHANGE_PROHIBITED", target = "regulated" },
]

tagging_policies = {
  "tag-policy-mandatory" = {
    description = "Mandatory tag policy: enforce allowed values for Environment, Team, CostCenter, ManagedBy"
    path        = "policies/tag-policy/tag-policy-mandatory.json"
    targets     = ["regulated", "non-regulated"]
  }
}

# All security services delegated to the central Security Tooling account
enable_delegation = {
  access_analyzer = { account_id = "111111111111" }
  cloudtrail      = { account_id = "111111111111" }
  config          = { account_id = "111111111111" }
  detective       = { account_id = "111111111111" }
  guardduty       = { account_id = "111111111111" }
  inspector       = { account_id = "111111111111" }
  macie           = { account_id = "111111111111" }
  securityhub     = { account_id = "111111111111" }
}
