locals {
  ciam_tenant_id = jsondecode(data.azapi_resource.entra.output).properties.tenantId
}

# Applies custom branding to the CIAM tenant via Microsoft Graph API.
#
# Prerequisites (one-time, manual):
#   1. Create an app registration inside the CIAM tenant.
#   2. Grant it the application permission: Organization.ReadWrite.All
#   3. Grant admin consent.
#   4. Create a client secret and store it in GitHub as a secret.
#
# Required image assets (optional — upload is skipped when files are absent):
#   assets/background.jpg   1920×1080 px  JPEG
#   assets/banner-logo.png   245×36  px  PNG
#   assets/square-logo.jpg  240×240  px  JPEG
#   assets/favicon.ico         32×32  px  ICO
#
# Runs `pwsh` (PowerShell 7+, present on ubuntu-latest in GitHub Actions).
resource "terraform_data" "branding" {
  triggers_replace = [
    filesha256("${path.module}/css/custom.css"),
    filesha256("${path.module}/scripts/apply-branding.ps1"),
    sha256(var.branding_sign_in_text),
    local.ciam_tenant_id,
  ]

  provisioner "local-exec" {
    interpreter = ["pwsh", "-File"]
    command     = "${path.module}/scripts/apply-branding.ps1"

    environment = {
      CLIENT_ID     = var.ciam_client_id
      CLIENT_SECRET = var.ciam_client_secret
      TENANT_ID     = local.ciam_tenant_id
      SIGN_IN_TEXT  = var.branding_sign_in_text
      CSS_PATH      = "${path.module}/css/custom.css"
      ASSETS_DIR    = "${path.module}/assets"
    }
  }
}
