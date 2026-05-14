output "apps" {
  description = "Deployed app registrations keyed by name, with app_id and object_id."
  value = {
    for name, mod in module.app : name => {
      app_id       = mod.app_id
      object_id    = mod.object_id
      display_name = mod.display_name
    }
  }
}
