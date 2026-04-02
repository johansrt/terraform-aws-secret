locals {
  common_tags = merge({
    ManagedBy = "Terraform"
  }, var.tags)

  # Normaliza nombres (evita //)
  normalized_secrets = {
    for k, v in var.secrets :
    k => merge(v, {
      name = replace("${var.prefix}${k}", "//", "/")
    })
  }

  # Procesamiento seguro del valor
  secrets_processed = {
    for k, v in local.normalized_secrets :
    k => merge(v, {
      secret_string = (
        can(v.secret_string["dummy"])
        ? jsonencode(v.secret_string)
        : tostring(v.secret_string)
      )
    })
  }
}

# =====================================================
# SECRET METADATA
# =====================================================

resource "aws_secretsmanager_secret" "this" {
  for_each = local.secrets_processed

  name                    = each.value.name
  description             = each.value.description
  kms_key_id              = try(each.value.kms_key_id, null)
  recovery_window_in_days = each.value.recovery_window_in_days

  tags = local.common_tags
}

# =====================================================
# SECRET VALUE (CONTROLLED DRIFT)
# =====================================================

resource "aws_secretsmanager_secret_version" "managed" {
  for_each = {
    for k, v in local.secrets_processed :
    k => v if !var.ignore_secret_changes
  }

  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = each.value.secret_string
}

resource "aws_secretsmanager_secret_version" "ignored" {
  for_each = {
    for k, v in local.secrets_processed :
    k => v if var.ignore_secret_changes
  }

  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = each.value.secret_string

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# =====================================================
# ROTATION
# =====================================================

resource "aws_secretsmanager_secret_rotation" "this" {
  for_each = {
    for k, v in local.secrets_processed :
    k => v if try(v.rotation_lambda_arn != null, false)
  }

  secret_id           = aws_secretsmanager_secret.this[each.key].id
  rotation_lambda_arn = each.value.rotation_lambda_arn

  dynamic "rotation_rules" {
    for_each = each.value.rotation_rules != null ? [each.value.rotation_rules] : []

    content {
      automatically_after_days = rotation_rules.value.automatically_after_days
    }
  }
}

# =====================================================
# RESOURCE POLICY (OPCIONAL)
# =====================================================

resource "aws_secretsmanager_secret_policy" "this" {
  for_each = var.resource_policy != null ? aws_secretsmanager_secret.this : {}

  secret_arn = each.value.arn
  policy     = var.resource_policy
}