output "load_balancer_public_ip" {
  value = module.infra.load_balancer_ip
}

output "arm_instance_public_ip" {
  value = module.infra.instances["app"].public_ip
}

output "ssh_to_arm" {
  value = module.infra.ssh_commands["app"]
}

output "main_db_ocid" {
  value = module.infra.database_ids["main"]
}

output "main_db_admin_password" {
  value     = module.infra.database_admin_passwords["main"]
  sensitive = true
}

output "vault_ocid" {
  value = module.infra.vault_id
}

output "os_namespace" {
  value = module.infra.os_namespace
}
