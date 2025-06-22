
variable "teams" {
  description = "Map of teams with group and permission set configuration"
  type = map(object({
    description  = string
    allowed_accounts   = list(string)

    permission_set = object({
      description               = string
      aws_managed_policies      = list(string)
      customer_managed_policies = list(string)
      session_duration           = optional(string, "PT12H") # ISO8601 - default 12h
    })
  }))
}

variable "accounts_aws" {
  description = "Map of AWS accounts with their account IDs"
  type = map(object({
    id = string
  }))
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags to apply to each account."
}
