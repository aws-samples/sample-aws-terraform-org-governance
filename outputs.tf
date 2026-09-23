# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

################################################################################
# Organization
################################################################################

output "organization_id" {
  description = "AWS Organization ID"
  value       = data.aws_organizations_organization.this.id
}

output "organization_arn" {
  description = "AWS Organization ARN"
  value       = data.aws_organizations_organization.this.arn
}

output "management_account_id" {
  description = "Management account ID"
  value       = data.aws_organizations_organization.this.master_account_id
}

################################################################################
# Organizational Units
################################################################################

output "organizational_units" {
  description = "Map of all OUs — key => { id, arn, name, parent_id }"
  value       = local.all_ou_attributes
}
