terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    mysql = {
      source  = "petoju/mysql"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "mysql" {
  endpoint = "${var.mysql_host}:${var.mysql_port}"
  username = var.admin_username
  password = var.admin_password
  tls      = "skip-verify"
}
