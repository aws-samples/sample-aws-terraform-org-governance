# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

locals {
  ##############################################################################
  # Organization lookups
  ##############################################################################

  # OUs that already exist directly under the root — chiefly Control Tower's
  # Security and Sandbox. Keyed lowercase so targets are case-insensitive.
  current_units = {
    for ou in data.aws_organizations_organizational_units.current.children : lower(ou.name) => ou.id
  }

  current_unit_arns = {
    for ou in data.aws_organizations_organizational_units.current.children : lower(ou.name) => ou.arn
  }

  root_ou = data.aws_organizations_organization.this.roots[0].id

  # CT baseline ARN — constructed from provider region.
  # "17BSJV3IGJ2QSGA2" is the fixed global identifier for the built-in
  # AWSControlTowerBaseline. It is stable across accounts and regions.
  # To confirm for your deployment, run:
  #   aws controltower list-baselines --query "baselines[?name=='AWSControlTowerBaseline']"
  ct_baseline_arn = "arn:aws:controltower:${data.aws_region.current.region}::baseline/17BSJV3IGJ2QSGA2"

  ##############################################################################
  # SCP content + attachments
  ##############################################################################

  scp_content = {
    for name, policy in var.scp_policies : name =>
    endswith(policy.path, ".tpl") ? templatefile(policy.path, policy.vars) : file(policy.path)
  }

  scp_attachments = {
    for item in flatten([
      for name, policy in var.scp_policies : [
        for target in policy.targets : {
          key    = "${name}/${target}"
          name   = name
          target = target
        }
      ]
    ]) : item.key => item
  }

  ##############################################################################
  # RCP content + attachments
  ##############################################################################

  rcp_content = {
    for name, policy in var.rcp_policies : name =>
    endswith(policy.path, ".tpl") ? templatefile(policy.path, policy.vars) : file(policy.path)
  }

  rcp_attachments = {
    for item in flatten([
      for name, policy in var.rcp_policies : [
        for target in policy.targets : {
          key    = "${name}/${target}"
          name   = name
          target = target
        }
      ]
    ]) : item.key => item
  }

  ##############################################################################
  # Tag policy content + attachments
  ##############################################################################

  tag_policy_content = {
    for name, policy in var.tagging_policies : name =>
    endswith(policy.path, ".tpl") ? templatefile(policy.path, policy.vars) : file(policy.path)
  }

  tag_policy_attachments = {
    for item in flatten([
      for name, policy in var.tagging_policies : [
        for target in policy.targets : {
          key    = "${name}/${target}"
          name   = name
          target = target
        }
      ]
    ]) : item.key => item
  }

  ##############################################################################
  # Backup policy content + attachments
  ##############################################################################

  backup_content = {
    for name, policy in var.backup_policies : name =>
    endswith(policy.path, ".tpl") ? templatefile(policy.path, policy.vars) : file(policy.path)
  }

  backup_attachments = {
    for item in flatten([
      for name, policy in var.backup_policies : [
        for target in policy.targets : {
          key    = "${name}/${target}"
          name   = name
          target = target
        }
      ]
    ]) : item.key => item
  }

  ##############################################################################
  # AI opt-out policy content + attachments
  ##############################################################################

  ai_opt_out_content = {
    for name, policy in var.ai_opt_out_policies : name =>
    endswith(policy.path, ".tpl") ? templatefile(policy.path, policy.vars) : file(policy.path)
  }

  ai_opt_out_attachments = {
    for item in flatten([
      for name, policy in var.ai_opt_out_policies : [
        for target in policy.targets : {
          key    = "${name}/${target}"
          name   = name
          target = target
        }
      ]
    ]) : item.key => item
  }

  ##############################################################################
  # Chatbot policy content + attachments
  ##############################################################################

  chatbot_content = {
    for name, policy in var.chatbot_policies : name =>
    endswith(policy.path, ".tpl") ? templatefile(policy.path, policy.vars) : file(policy.path)
  }

  chatbot_attachments = {
    for item in flatten([
      for name, policy in var.chatbot_policies : [
        for target in policy.targets : {
          key    = "${name}/${target}"
          name   = name
          target = target
        }
      ]
    ]) : item.key => item
  }

  ##############################################################################
  # OU flattening — per-level argument lists
  ##############################################################################

  level_1_ou_arguments = [
    for ou in var.organization.units : {
      name        = ou.name
      key         = ou.key
      ct_register = ou.ct_register
    }
  ]

  level_2_ou_arguments = flatten([
    for l1 in var.organization.units : [
      for l2 in l1.units : {
        name        = l2.name
        key         = l2.key
        parent      = l1.key
        ct_register = l2.ct_register
      }
    ]
  ])

  level_3_ou_arguments = flatten([
    for l1 in var.organization.units : [
      for l2 in l1.units : [
        for l3 in l2.units : {
          name        = l3.name
          key         = l3.key
          parent      = l2.key
          ct_register = l3.ct_register
        }
      ]
    ]
  ])

  level_4_ou_arguments = flatten([
    for l1 in var.organization.units : [
      for l2 in l1.units : [
        for l3 in l2.units : [
          for l4 in l3.units : {
            name        = l4.name
            key         = l4.key
            parent      = l3.key
            ct_register = l4.ct_register
          }
        ]
      ]
    ]
  ])

  level_5_ou_arguments = flatten([
    for l1 in var.organization.units : [
      for l2 in l1.units : [
        for l3 in l2.units : [
          for l4 in l3.units : [
            for l5 in l4.units : {
              name        = l5.name
              key         = l5.key
              parent      = l4.key
              ct_register = l5.ct_register
            }
          ]
        ]
      ]
    ]
  ])

  ##############################################################################
  # CT control attachments
  ##############################################################################

  ct_control_attachments = {
    for a in var.ct_controls : "${a.target}/${a.control}" => {
      ou_key  = a.target
      control = a.control
    }
  }
}

################################################################################
# OU attribute projections — second pass so resources can be referenced
################################################################################

locals {
  level_1_ou_attributes = [
    for ou in local.level_1_ou_arguments : {
      key       = ou.key
      id        = aws_organizations_organizational_unit.level_1_ous[ou.key].id
      arn       = aws_organizations_organizational_unit.level_1_ous[ou.key].arn
      parent_id = aws_organizations_organizational_unit.level_1_ous[ou.key].parent_id
      name      = aws_organizations_organizational_unit.level_1_ous[ou.key].name
    }
  ]

  level_2_ou_attributes = [
    for ou in local.level_2_ou_arguments : {
      key       = ou.key
      id        = aws_organizations_organizational_unit.level_2_ous[ou.key].id
      arn       = aws_organizations_organizational_unit.level_2_ous[ou.key].arn
      parent_id = aws_organizations_organizational_unit.level_2_ous[ou.key].parent_id
      name      = aws_organizations_organizational_unit.level_2_ous[ou.key].name
    }
  ]

  level_3_ou_attributes = [
    for ou in local.level_3_ou_arguments : {
      key       = ou.key
      id        = aws_organizations_organizational_unit.level_3_ous[ou.key].id
      arn       = aws_organizations_organizational_unit.level_3_ous[ou.key].arn
      parent_id = aws_organizations_organizational_unit.level_3_ous[ou.key].parent_id
      name      = aws_organizations_organizational_unit.level_3_ous[ou.key].name
    }
  ]

  level_4_ou_attributes = [
    for ou in local.level_4_ou_arguments : {
      key       = ou.key
      id        = aws_organizations_organizational_unit.level_4_ous[ou.key].id
      arn       = aws_organizations_organizational_unit.level_4_ous[ou.key].arn
      parent_id = aws_organizations_organizational_unit.level_4_ous[ou.key].parent_id
      name      = aws_organizations_organizational_unit.level_4_ous[ou.key].name
    }
  ]

  level_5_ou_attributes = [
    for ou in local.level_5_ou_arguments : {
      key       = ou.key
      id        = aws_organizations_organizational_unit.level_5_ous[ou.key].id
      arn       = aws_organizations_organizational_unit.level_5_ous[ou.key].arn
      parent_id = aws_organizations_organizational_unit.level_5_ous[ou.key].parent_id
      name      = aws_organizations_organizational_unit.level_5_ous[ou.key].name
    }
  ]

  all_ou_attributes = {
    for ou in concat(
      local.level_1_ou_attributes,
      local.level_2_ou_attributes,
      local.level_3_ou_attributes,
      local.level_4_ou_attributes,
      local.level_5_ou_attributes
    ) : ou.key => ou
  }

  ##############################################################################
  # Attachment target resolution
  #
  # A policy `targets` entry or a ct_controls `target` may name an OU created
  # here (by its `key`), an OU that already exists under the root (by name,
  # e.g. Control Tower's Security), or — for policies only — "root". Lookups
  # are lowercased, so casing in tfvars does not matter. OU keys created here
  # win over same-named pre-existing OUs.
  ##############################################################################

  policy_target_ids = merge(
    local.current_units,
    { for key, ou in local.all_ou_attributes : lower(key) => ou.id },
    { root = local.root_ou },
  )

  # Control Tower controls target an OU ARN and cannot target the root.
  control_target_arns = merge(
    local.current_unit_arns,
    { for key, ou in local.all_ou_attributes : lower(key) => ou.arn },
  )
}
