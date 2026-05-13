# Registers Facebook as a social identity provider in the CIAM tenant via Microsoft Graph API.
#
# Prerequisites (one-time, manual):
#   1. Add application permission IdentityProvider.ReadWrite.All to the CIAM app registration.
#   2. Grant admin consent for that permission inside the CIAM tenant.
#
# The Facebook OAuth2 app (client_id / client_secret) must be created in the Facebook
# Developer Portal and passed in as variables.
#
resource "terraform_data" "facebook_idp" {
  count = var.facebook_client_id != null ? 1 : 0

  triggers_replace = [
    var.facebook_client_id,
    local.ciam_tenant_id,
    filesha256("${path.module}/scripts/apply-facebook-idp.ps1"),
    filesha256("${path.module}/scripts/idp-helpers.ps1"),
  ]

  provisioner "local-exec" {
    interpreter = ["pwsh", "-File"]
    command     = "${path.module}/scripts/apply-facebook-idp.ps1"

    environment = {
      CLIENT_ID              = var.ciam_client_id
      CLIENT_SECRET          = var.ciam_client_secret
      TENANT_ID              = local.ciam_tenant_id
      FACEBOOK_CLIENT_ID     = var.facebook_client_id
      FACEBOOK_CLIENT_SECRET = var.facebook_client_secret
    }
  }
}
