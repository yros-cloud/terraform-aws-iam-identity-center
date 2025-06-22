# Data Sources
data "aws_ssoadmin_instances" "sso" {}

# This local variable extracts the first SSO instance ID and ARN
# from the data source, which is useful for subsequent resource definitions.
locals {
  identity_store_id  = tolist(data.aws_ssoadmin_instances.sso.identity_store_ids)[0]
  identity_store_arn = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
}

locals {
  tags = merge(
    var.tags,
    {
      "CreatedBy" = "Terraform"
      "Module"    = "aws-foundation-iam-identity-center"
    }
  )
}


##############################
# Identity Store Groups
##############################

resource "aws_identitystore_group" "group" {
  for_each          = var.teams
  identity_store_id = local.identity_store_id
  display_name      = each.key
  description       = each.value.description
}


##############################
# Permission Sets
##############################

resource "aws_ssoadmin_permission_set" "this" {
  for_each = var.teams

  name             = each.key
  instance_arn     = local.identity_store_arn
  description      = each.value.permission_set.description
  session_duration = each.value.permission_set.session_duration
  tags = local.tags
}

##############################
# Managed Policy Attachments
##############################

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each = {
    for pair in flatten([
      for team_name, team in var.teams : [
        for arn in team.permission_set.aws_managed_policies : {
          key        = "${team_name}-${replace(arn, "/", "_")}"
          team_name  = team_name
          policy_arn = arn
        }
      ]
    ]) : pair.key => pair
  }

  instance_arn       = local.identity_store_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.team_name].arn
  managed_policy_arn = each.value.policy_arn
}

##############################
# Custom Policy Attachments
##############################
resource "aws_ssoadmin_customer_managed_policy_attachment" "this" {
  for_each = {
    for pair in flatten([
      for team_name, team in var.teams : [
        for name in team.permission_set.customer_managed_policies : {
          key         = "${team_name}-${name}"
          team_name   = team_name
          policy_name = name
        }
      ]
    ]) : pair.key => pair
  }

  instance_arn       = local.identity_store_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.team_name].arn

  customer_managed_policy_reference {
    name = each.value.policy_name
    path = "/"
  }
}


##############################
# Account Assignments
##############################
resource "aws_ssoadmin_account_assignment" "assignments" {
  for_each = {
    for pair in flatten([
      for team_name, team in var.teams :
      team.allowed_accounts != null && length(team.allowed_accounts) > 0 ? [
        for account_key in team.allowed_accounts : {
          key        = "${team_name}-${account_key}"
          team_name  = team_name
          account_id = var.accounts_aws[account_key].id
        }
      ] : []
    ]) : pair.key => pair
  }

  instance_arn       = local.identity_store_arn
  permission_set_arn = aws_ssoadmin_permission_set.this[each.value.team_name].arn

  principal_id   = aws_identitystore_group.group[each.value.team_name].group_id
  principal_type = "GROUP"

  target_id   = each.value.account_id
  target_type = "AWS_ACCOUNT"
}


##############################
# All Outputs
##############################

output "identitystore_groups" {
  description = "Mapeamento dos grupos criados no Identity Store"
  value = {
    for k, g in aws_identitystore_group.group :
    k => {
      group_id     = g.group_id
      display_name = g.display_name
    }
  }
}

output "permission_sets" {
  description = "Mapeamento dos Permission Sets criados"
  value = {
    for k, p in aws_ssoadmin_permission_set.this :
    k => {
      arn         = p.arn
      name        = p.name
      description = p.description
    }
  }
}

output "account_assignments" {
  value = {
    for k, a in aws_ssoadmin_account_assignment.assignments :
    k => {
      team_name         = a.principal_id != "" ? k : null
      permission_set_arn = a.permission_set_arn
      account_id         = a.target_id
    }
  }
}
