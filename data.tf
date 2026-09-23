# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

data "aws_region" "current" {}

data "aws_organizations_organization" "this" {}

data "aws_organizations_organizational_units" "current" {
  parent_id = data.aws_organizations_organization.this.roots[0].id
}
