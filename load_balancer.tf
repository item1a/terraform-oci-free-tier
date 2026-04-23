# --- Load Balancer (only when Cloudflare is enabled) ---

resource "oci_load_balancer_load_balancer" "lb" {
  count          = var.enable_cloudflare ? 1 : 0
  compartment_id = var.tenancy_ocid
  display_name   = "${var.project_name} Load Balancer"
  subnet_ids     = [oci_core_subnet.public.id]
  shape          = "flexible"
  shape_details {
    maximum_bandwidth_in_mbps = 10
    minimum_bandwidth_in_mbps = 10
  }
  network_security_group_ids = [oci_core_network_security_group.lb_nsg[0].id]
}

resource "oci_load_balancer_backend_set" "backend" {
  count            = var.enable_cloudflare ? 1 : 0
  load_balancer_id = oci_load_balancer_load_balancer.lb[0].id
  name             = "backend-set"
  policy           = "ROUND_ROBIN"
  health_checker {
    protocol = "HTTP"
    port     = var.app_port
    url_path = "/health"
  }
}

resource "oci_load_balancer_backend" "app" {
  count            = var.enable_cloudflare ? 1 : 0
  load_balancer_id = oci_load_balancer_load_balancer.lb[0].id
  backendset_name  = oci_load_balancer_backend_set.backend[0].name
  ip_address       = oci_core_instance.arm.private_ip
  port             = var.app_port
}

resource "oci_load_balancer_listener" "https" {
  count                    = var.enable_cloudflare ? 1 : 0
  load_balancer_id         = oci_load_balancer_load_balancer.lb[0].id
  default_backend_set_name = oci_load_balancer_backend_set.backend[0].name
  name                     = "https-listener"
  protocol                 = "HTTP"
  port                     = 443

  ssl_configuration {
    certificate_name        = oci_load_balancer_certificate.origin[0].certificate_name
    verify_peer_certificate = false
  }
}
