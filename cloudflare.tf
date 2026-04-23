# --- Cloudflare Origin Certificate + DNS ---

resource "tls_private_key" "origin" {
  count     = var.enable_cloudflare ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "origin" {
  count           = var.enable_cloudflare ? 1 : 0
  private_key_pem = tls_private_key.origin[0].private_key_pem
  subject {
    common_name = var.domain_name
  }
}

resource "cloudflare_origin_ca_certificate" "cert" {
  count              = var.enable_cloudflare ? 1 : 0
  csr                = tls_cert_request.origin[0].cert_request_pem
  hostnames          = [var.domain_name, "*.${var.domain_name}"]
  request_type       = "origin-rsa"
  requested_validity = 5475 # 15 years
}

# Cloudflare Origin CA RSA root certificate
locals {
  cloudflare_origin_ca_rsa_root = <<-EOT
-----BEGIN CERTIFICATE-----
MIIEADCCAuigAwIBAgIID+rOSdTGfGcwDQYJKoZIhvcNAQELBQAwgYsxCzAJBgNV
BAYTAlVTMRkwFwYDVQQKExBDbG91ZEZsYXJlLCBJbmMuMTQwMgYDVQQLEytDbG91
ZEZsYXJlIE9yaWdpbiBTU0wgQ2VydGlmaWNhdGUgQXV0aG9yaXR5MRYwFAYDVQQH
Ew1TYW4gRnJhbmNpc2NvMRMwEQYDVQQIEwpDYWxpZm9ybmlhMB4XDTE5MDgyMzIx
MDgwMFoXDTI5MDgxNTE3MDAwMFowgYsxCzAJBgNVBAYTAlVTMRkwFwYDVQQKExBD
bG91ZEZsYXJlLCBJbmMuMTQwMgYDVQQLEytDbG91ZEZsYXJlIE9yaWdpbiBTU0wg
Q2VydGlmaWNhdGUgQXV0aG9yaXR5MRYwFAYDVQQHEw1TYW4gRnJhbmNpc2NvMRMw
EQYDVQQIEwpDYWxpZm9ybmlhMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
AQEAwEiVZ/UoQpHmFsHvk5isBxRehukP8DG9JhFev3WZtG76WoTthvLJFRKFCHXm
V6Z5/66Z4S09mgsUuFwvJzMnE6Ej6yIsYNCb9r9QORa8BdhrkNn6kdTly3mdnykb
OomnwbUfLlExVgNdlP0XoRoeMwbQ4598foiHblO2B/LKuNfJzAMfS7oZe34b+vLB
yrP/1bgCSLdc1AxQc1AC0EsQQhgcyTJNgnG4va1c7ogPlwKyhbDyZ4e59N5lbYPJ
SmXI/cAe3jXj1FBLJZkwnoDKe0v13xeF+nF32smSH0qB7aJX2tBMW4TWtFPmzs5I
lwrFSySWAdwYdgxw180yKU0dvwIDAQABo2YwZDAOBgNVHQ8BAf8EBAMCAQYwEgYD
VR0TAQH/BAgwBgEB/wIBAjAdBgNVHQ4EFgQUJOhTV118NECHqeuU27rhFnj8KaQw
HwYDVR0jBBgwFoAUJOhTV118NECHqeuU27rhFnj8KaQwDQYJKoZIhvcNAQELBQAD
ggEBAHwOf9Ur1l0Ar5vFE6PNrZWrDfQIMyEfdgSKofCdTckbqXNTiXdgbHs+TWoQ
wAB0pfJDAHJDXOTCWRyTeXOseeOi5Btj5CnEuw3P0oXqdqevM1/+uWp0CM35zgZ8
VD4aITxity0djzE6Qnx3Syzz+ZkoBgTnNum7d9A66/V636x4vTeqbZFBr9erJzgz
hhurjcoacvRNhnjtDRM0dPeiCJ50CP3wEYuvUzDHUaowOsnLCjQIkWbR7Ni6KEIk
MOz2U0OBSif3FTkhCgZWQKOOLo1P42jHC3ssUZAtVNXrCk3fw9/E15k8NPkBazZ6
0iykLhH1trywrKRMVw67F44IE8Y=
-----END CERTIFICATE-----
EOT
}

resource "oci_load_balancer_certificate" "origin" {
  count            = var.enable_cloudflare ? 1 : 0
  certificate_name = "cloudflare-origin-cert"
  load_balancer_id = oci_load_balancer_load_balancer.lb[0].id

  public_certificate = cloudflare_origin_ca_certificate.cert[0].certificate
  private_key        = tls_private_key.origin[0].private_key_pem
  ca_certificate     = local.cloudflare_origin_ca_rsa_root

  lifecycle {
    create_before_destroy = true
  }
}

# --- DNS Records ---

resource "cloudflare_record" "dns" {
  for_each = var.enable_cloudflare ? toset(var.dns_records) : toset([])
  zone_id  = var.cloudflare_zone_id
  name     = each.value
  content  = [for ip in oci_load_balancer_load_balancer.lb[0].ip_address_details : ip.ip_address if ip.is_public][0]
  type     = "A"
  proxied  = true
}

resource "cloudflare_zone_settings_override" "ssl" {
  count   = var.enable_cloudflare ? 1 : 0
  zone_id = var.cloudflare_zone_id
  settings {
    ssl = "strict"
  }
}
