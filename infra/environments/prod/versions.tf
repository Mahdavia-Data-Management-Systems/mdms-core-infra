terraform {
  required_version = ">= 1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.15"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
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

provider "azapi" {
  subscription_id = var.subscription_id
}
