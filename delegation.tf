# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

################################################################################
# Organizations delegation
################################################################################

resource "aws_organizations_delegated_administrator" "organizations" {
  count             = var.enable_delegation.organizations != null ? 1 : 0
  account_id        = var.enable_delegation.organizations.account_id
  service_principal = "organizations.amazonaws.com"
}

################################################################################
# CloudFormation StackSets delegation
################################################################################

resource "aws_organizations_delegated_administrator" "stacksets" {
  count             = var.enable_delegation.stacksets != null ? 1 : 0
  account_id        = var.enable_delegation.stacksets.account_id
  service_principal = "member.org.stacksets.cloudformation.amazonaws.com"
}

################################################################################
# IAM Access Analyzer delegation
################################################################################

resource "aws_organizations_delegated_administrator" "access_analyzer" {
  count             = var.enable_delegation.access_analyzer != null ? 1 : 0
  account_id        = var.enable_delegation.access_analyzer.account_id
  service_principal = "access-analyzer.amazonaws.com"
}

resource "aws_iam_service_linked_role" "access_analyzer" {
  count            = var.enable_delegation.access_analyzer != null ? 1 : 0
  aws_service_name = "access-analyzer.amazonaws.com"
}

################################################################################
# GuardDuty delegation
################################################################################

resource "aws_guardduty_organization_admin_account" "this" {
  count            = var.enable_delegation.guardduty != null ? 1 : 0
  admin_account_id = var.enable_delegation.guardduty.account_id
}

################################################################################
# Security Hub delegation
################################################################################

resource "aws_securityhub_organization_admin_account" "this" {
  count            = var.enable_delegation.securityhub != null ? 1 : 0
  admin_account_id = var.enable_delegation.securityhub.account_id
}

################################################################################
# Macie delegation
################################################################################

resource "aws_macie2_account" "this" {
  count = var.enable_delegation.macie != null ? 1 : 0
}

resource "aws_macie2_organization_admin_account" "this" {
  count            = var.enable_delegation.macie != null ? 1 : 0
  admin_account_id = var.enable_delegation.macie.account_id
  depends_on       = [aws_macie2_account.this]
}

################################################################################
# Inspector delegation
################################################################################

resource "aws_inspector2_delegated_admin_account" "this" {
  count      = var.enable_delegation.inspector != null ? 1 : 0
  account_id = var.enable_delegation.inspector.account_id
}

################################################################################
# IPAM delegation
################################################################################

resource "aws_vpc_ipam_organization_admin_account" "this" {
  count                      = var.enable_delegation.ipam != null ? 1 : 0
  delegated_admin_account_id = var.enable_delegation.ipam.account_id
}

################################################################################
# Config delegation
################################################################################

resource "aws_organizations_delegated_administrator" "config" {
  count             = var.enable_delegation.config != null ? 1 : 0
  account_id        = var.enable_delegation.config.account_id
  service_principal = "config.amazonaws.com"
}

################################################################################
# CloudTrail delegation
################################################################################

resource "aws_cloudtrail_organization_delegated_admin_account" "this" {
  count      = var.enable_delegation.cloudtrail != null ? 1 : 0
  account_id = var.enable_delegation.cloudtrail.account_id
}

################################################################################
# Detective delegation
################################################################################

resource "aws_detective_organization_admin_account" "this" {
  count      = var.enable_delegation.detective != null ? 1 : 0
  account_id = var.enable_delegation.detective.account_id
}

################################################################################
# Firewall Manager delegation
################################################################################

resource "aws_fms_admin_account" "this" {
  count      = var.enable_delegation.firewall_manager != null ? 1 : 0
  account_id = var.enable_delegation.firewall_manager.account_id
}

################################################################################
# IAM Identity Center (SSO) delegation
################################################################################

resource "aws_organizations_delegated_administrator" "sso" {
  count             = var.enable_delegation.sso != null ? 1 : 0
  account_id        = var.enable_delegation.sso.account_id
  service_principal = "sso.amazonaws.com"
}

################################################################################
# AWS Backup delegation
################################################################################

resource "aws_organizations_delegated_administrator" "backup" {
  count             = var.enable_delegation.backup != null ? 1 : 0
  account_id        = var.enable_delegation.backup.account_id
  service_principal = "backup.amazonaws.com"
}

################################################################################
# Systems Manager delegation
################################################################################

resource "aws_organizations_delegated_administrator" "ssm" {
  count             = var.enable_delegation.systems_manager != null ? 1 : 0
  account_id        = var.enable_delegation.systems_manager.account_id
  service_principal = "ssm.amazonaws.com"
}
