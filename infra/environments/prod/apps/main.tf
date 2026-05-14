locals {
  apps = yamldecode(file("${path.module}/apps.yaml")).apps
}

module "app" {
  for_each = { for app in local.apps : app.name => app }
  source   = "../../../modules/entra-app"

  resource_group_name = "rg-mdms-prod-si-01"
  domain_name         = "mahdavisonline.onmicrosoft.com"
  ciam_client_id      = var.ciam_client_id
  ciam_client_secret  = var.ciam_client_secret

  display_name     = each.value.display_name
  app_type         = try(each.value.app_type, "spa")
  redirect_uris    = try(each.value.redirect_uris, [])
  logout_url       = try(each.value.logout_url, null)
  sign_in_audience = try(each.value.sign_in_audience, "AzureADandPersonalMicrosoftAccount")
}
