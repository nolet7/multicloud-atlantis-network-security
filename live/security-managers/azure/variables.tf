variable "location" {
  type    = string
  default = "eastus"
}

variable "environment" {
  type    = string
  default = "shared"
}

variable "key_vault_name" {
  type        = string
  description = "Globally unique Key Vault name, for example kv-mc-atlantis-001"
}
