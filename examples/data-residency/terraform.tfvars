# Data Residency Example — Region-locked workloads
#
# Use case: Data sovereignty requirements (GDPR, SOC 2, country-specific
# regulations) that mandate data must stay within approved regions.
#
# What this sets up:
#   Root
#   ├── EU-Workloads     (locked to eu-west-1, eu-central-1)
#   └── US-Workloads     (locked to us-east-1, us-west-2)
#
# Data residency is enforced via the CT Region Deny control plus
# data-residency specific controls that prevent cross-region networking
# and public access.
#
# Additional org-level controls:
# - RCP: require SSL on data services (applies to external principals too)
# - AI opt-out: prevent AWS from processing sovereign data for AI/ML training

tags = {
  Project    = "org-governance"
  ManagedBy  = "Terraform"
  Compliance = "DataResidency"
}

organization = {
  units = [
    {
      name        = "EU-Workloads"
      key         = "eu-workloads"
      ct_register = true
    },
    {
      name        = "US-Workloads"
      key         = "us-workloads"
      ct_register = true
    },
  ]
}

scp_policies = {
  "scp-foundation-guardrails" = {
    description = "Foundation: deny org leave, IMDSv2, encryption, RAM external sharing"
    path        = "policies/scp/scp-foundation-guardrails.json.tpl"
    vars        = { breakglass_role = "BreakGlass-Admin" }
    targets     = ["eu-workloads", "us-workloads"]
  }
}

rcp_policies = {
  "rcp-require-ssl" = {
    description = "Require SSL for S3, SQS, Secrets Manager — enforces in-transit encryption across accounts"
    path        = "policies/rcp/rcp-require-ssl.json"
    vars        = {}
    targets     = ["eu-workloads", "us-workloads"]
  }
}

ai_opt_out_policies = {
  "ai-opt-out-all" = {
    description = "Opt out of AWS using org content for AI/ML training — required for GDPR"
    path        = "policies/ai-opt-out/ai-opt-out-all.json"
    targets     = ["root"]
  }
}

ct_baseline_version             = "5.0"
ct_identity_center_baseline_arn = ""
enable_ram_sharing              = false

# Data residency controls — prevent anything from leaving the region
ct_controls = [
  # Cross-region / egress prevention
  { control = "AWS-GR_DISALLOW_CROSS_REGION_NETWORKING", target = "eu-workloads" },
  { control = "AWS-GR_DISALLOW_CROSS_REGION_NETWORKING", target = "us-workloads" },
  { control = "AWS-GR_DISALLOW_VPC_INTERNET_ACCESS", target = "eu-workloads" },
  { control = "AWS-GR_DISALLOW_VPC_INTERNET_ACCESS", target = "us-workloads" },
  { control = "AWS-GR_DISALLOW_VPN_CONNECTIONS", target = "eu-workloads" },
  { control = "AWS-GR_DISALLOW_VPN_CONNECTIONS", target = "us-workloads" },
  { control = "AWS-GR_RESTRICT_S3_CROSS_REGION_REPLICATION", target = "eu-workloads" },
  { control = "AWS-GR_RESTRICT_S3_CROSS_REGION_REPLICATION", target = "us-workloads" },

  # Public access prevention (data must not leak externally)
  { control = "AWS-GR_EC2_INSTANCE_NO_PUBLIC_IP", target = "eu-workloads" },
  { control = "AWS-GR_EC2_INSTANCE_NO_PUBLIC_IP", target = "us-workloads" },
  { control = "AWS-GR_SUBNET_AUTO_ASSIGN_PUBLIC_IP_DISABLED", target = "eu-workloads" },
  { control = "AWS-GR_SUBNET_AUTO_ASSIGN_PUBLIC_IP_DISABLED", target = "us-workloads" },
  { control = "AWS-GR_NO_UNRESTRICTED_ROUTE_TO_IGW", target = "eu-workloads" },
  { control = "AWS-GR_NO_UNRESTRICTED_ROUTE_TO_IGW", target = "us-workloads" },
  { control = "AWS-GR_S3_ACCOUNT_LEVEL_PUBLIC_ACCESS_BLOCKS_PERIODIC", target = "eu-workloads" },
  { control = "AWS-GR_S3_ACCOUNT_LEVEL_PUBLIC_ACCESS_BLOCKS_PERIODIC", target = "us-workloads" },

  # Managed service public access
  { control = "AWS-GR_RDS_INSTANCE_PUBLIC_ACCESS_CHECK", target = "eu-workloads" },
  { control = "AWS-GR_RDS_INSTANCE_PUBLIC_ACCESS_CHECK", target = "us-workloads" },
  { control = "AWS-GR_LAMBDA_FUNCTION_PUBLIC_ACCESS_PROHIBITED", target = "eu-workloads" },
  { control = "AWS-GR_LAMBDA_FUNCTION_PUBLIC_ACCESS_PROHIBITED", target = "us-workloads" },
  { control = "AWS-GR_ELASTICSEARCH_IN_VPC_ONLY", target = "eu-workloads" },
  { control = "AWS-GR_ELASTICSEARCH_IN_VPC_ONLY", target = "us-workloads" },
  { control = "AWS-GR_SAGEMAKER_NOTEBOOK_NO_DIRECT_INTERNET_ACCESS", target = "eu-workloads" },
  { control = "AWS-GR_SAGEMAKER_NOTEBOOK_NO_DIRECT_INTERNET_ACCESS", target = "us-workloads" },
]

tagging_policies = {
  "tag-policy-mandatory" = {
    description = "Mandatory tag policy: enforce allowed values for Environment, Team, CostCenter, ManagedBy"
    path        = "policies/tag-policy/tag-policy-mandatory.json"
    targets     = ["eu-workloads", "us-workloads"]
  }
}
