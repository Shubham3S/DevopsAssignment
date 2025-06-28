variable "resource_group_name" {
  type    = string
  default = "rg-billing-optimizer"
}

variable "location" {
  type    = string
  default = "East US"
}

variable "storage_account_name" {
  type    = string
  default = "billingarchivestg"
}

variable "cosmos_account_name" {
  type    = string
  default = "billingcosmosdb"
}

variable "prefix" {
  type    = string
  default = "billingopt"
}
