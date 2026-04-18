terraform {
  required_version = ">= 1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }

  cloud {
    organization = "noormahdi"

    workspaces {
      name = "core-prod"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}
