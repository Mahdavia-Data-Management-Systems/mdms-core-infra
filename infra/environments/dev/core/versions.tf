terraform {
  required_version = ">= 1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.5"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.12"
    }
  }

  cloud {
    organization = "MDMS"

    workspaces {
      name = "core-dev"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azapi" {
  subscription_id = var.subscription_id
}
