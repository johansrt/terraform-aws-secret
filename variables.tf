variable "prefix" {
  description = "Prefijo jerárquico (ej: /project/env/app/)."
  type        = string
}

variable "secrets" {
  description = "Mapa de secretos a crear."
  type = map(object({
    description             = string
    secret_string           = any
    kms_key_id              = optional(string)
    recovery_window_in_days = optional(number, 30)

    rotation_lambda_arn = optional(string)
    rotation_rules = optional(object({
      automatically_after_days = number
    }))
  }))

  validation {
    condition = alltrue([
      for s in var.secrets :
      s.rotation_lambda_arn == null || s.rotation_rules != null
    ])
    error_message = "rotation_rules must be defined when rotation_lambda_arn is provided."
  }

  validation {
    condition = alltrue([
      for s in var.secrets :
      s.rotation_rules == null || s.rotation_rules.automatically_after_days >= 1
    ])
    error_message = "Rotation days must be >= 1."
  }
}

variable "ignore_secret_changes" {
  description = "Ignora cambios en el valor del secreto (recomendado para rotación externa)."
  type        = bool
  default     = true
}

variable "resource_policy" {
  description = "Policy JSON opcional para controlar acceso al secreto."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags comunes."
  type        = map(string)
  default     = {}
}