output "load_balancer_public_ip" {
  value = module.cloudflare.load_balancer_ip
}

output "arm_instance_public_ip" {
  value = module.core.instances["app"].public_ip
}

output "ssh_to_arm" {
  value = module.core.ssh_commands["app"]
}

output "main_db_ocid" {
  value = module.core.database_ids["main"]
}

output "main_db_admin_password" {
  value     = module.core.database_admin_passwords["main"]
  sensitive = true
}

output "vault_ocid" {
  value = module.core.vault_id
}

output "os_namespace" {
  value = module.core.os_namespace
}
