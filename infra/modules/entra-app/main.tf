data "azurerm_resource_group" "entra" {
  name = var.resource_group_name
}

data "azapi_resource" "entra" {
  type      = "Microsoft.AzureActiveDirectory/ciamDirectories@2023-05-17-preview"
  name      = var.domain_name
  parent_id = data.azurerm_resource_group.entra.id

  response_export_values = ["properties.tenantId"]
}

locals {
  tenant_id = jsondecode(data.azapi_resource.entra.output).properties.tenantId
}

resource "terraform_data" "app" {
  # Indices: [0]=tenant_id [1]=display_name [2]=app_type [3]=sign_in_audience
  #          [4]=redirect_uris [5]=logout_url [6]=client_id [7]=client_secret
  #          [8]=apply-app.ps1 [9]=app-helpers.ps1 [10]=delete-app.ps1
  triggers_replace = [
    local.tenant_id,
    var.display_name,
    var.app_type,
    var.sign_in_audience,
    jsonencode(var.redirect_uris),
    var.logout_url,
    var.ciam_client_id,
    var.ciam_client_secret,
    filesha256("${path.module}/scripts/apply-app.ps1"),
    filesha256("${path.module}/scripts/app-helpers.ps1"),
    filesha256("${path.module}/scripts/delete-app.ps1"),
  ]

  provisioner "local-exec" {
    interpreter = ["pwsh", "-File"]
    command     = "${path.module}/scripts/apply-app.ps1"

    environment = {
      CLIENT_ID        = var.ciam_client_id
      CLIENT_SECRET    = var.ciam_client_secret
      TENANT_ID        = local.tenant_id
      DISPLAY_NAME     = var.display_name
      APP_TYPE         = var.app_type
      REDIRECT_URIS    = jsonencode(var.redirect_uris)
      LOGOUT_URL       = var.logout_url != null ? var.logout_url : ""
      SIGN_IN_AUDIENCE = var.sign_in_audience
    }
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["pwsh", "-File"]
    command     = "${path.module}/scripts/delete-app.ps1"

    environment = {
      TENANT_ID     = self.triggers_replace[0]
      DISPLAY_NAME  = self.triggers_replace[1]
      CLIENT_ID     = self.triggers_replace[6]
      CLIENT_SECRET = self.triggers_replace[7]
    }
  }
}

data "external" "app" {
  program = ["pwsh", "-File", "${path.module}/scripts/get-app.ps1"]

  query = {
    tenant_id     = local.tenant_id
    client_id     = var.ciam_client_id
    client_secret = var.ciam_client_secret
    display_name  = var.display_name
  }

  depends_on = [terraform_data.app]
}
