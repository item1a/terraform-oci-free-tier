output "load_balancer_ip" {
  value = [for ip in oci_load_balancer_load_balancer.lb.ip_address_details : ip.ip_address if ip.is_public][0]
}

output "load_balancer_id" {
  value = oci_load_balancer_load_balancer.lb.id
}
