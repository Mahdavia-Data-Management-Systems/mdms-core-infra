# Registers Google as a social identity provider in the CIAM tenant via Microsoft Graph API.
#
# Prerequisites (one-time, manual):
#   1. Add application permission IdentityProvider.ReadWrite.All to the CIAM app registration.
#   2. Grant admin consent for that permission inside the CIAM tenant.
#
# The Google OAuth2 client (client_id / client_secret) is provisioned separately by
# the google-oauth module and passed in as variables.
#
resource "terraform_data" "google_idp" {
  triggers_replace = [
    var.google_client_id,
    local.ciam_tenant_id,
    filesha256("${path.module}/scripts/apply-google-idp.ps1"),
  ]

  provisioner "local-exec" {
    interpreter = ["pwsh", "-File"]
    command     = "${path.module}/scripts/apply-google-idp.ps1"

    environment = {
      CLIENT_ID            = var.ciam_client_id
      CLIENT_SECRET        = var.ciam_client_secret
      TENANT_ID            = local.ciam_tenant_id
      GOOGLE_CLIENT_ID     = var.google_client_id
      GOOGLE_CLIENT_SECRET = var.google_client_secret
    }
  }
}
