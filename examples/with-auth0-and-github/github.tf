# Syncs GitHub Actions secrets from Terraform state. After `terraform apply`
# your CI/CD workflow has every credential and OCID it needs.
#
# Edit the `github_secrets` map to match what your workflow consumes.

data "github_repository" "repo" {
  full_name = "${var.GITHUB_OWNER}/${var.GITHUB_REPO}"
}

locals {
  github_secrets = {
    # OCI auth
    OCI_TENANCY_OCID = var.TENANCY_OCID
    OCI_USER_OCID    = var.USER_OCID
    OCI_FINGERPRINT  = var.FINGERPRINT
    OCI_PRIVATE_KEY  = local.oci_private_key
    OCI_REGION       = var.REGION

    # SSH (deploy job uses these to scp/ssh to the ARM instance)
    SSH_PRIVATE_KEY = local.ssh_private_key
    SSH_PUBLIC_KEY  = local.ssh_public_key
    IP_ADDRESS      = var.IP_ADDRESS

    # Cloudflare
    CLOUDFLARE_API_TOKEN = var.CLOUDFLARE_API_TOKEN
    CLOUDFLARE_ZONE_ID   = var.CLOUDFLARE_ZONE_ID
    DOMAIN_NAME          = var.DOMAIN_NAME

    # Auth0
    AUTH0_DOMAIN            = var.AUTH0_DOMAIN
    AUTH0_CLIENT_ID         = var.AUTH0_CLIENT_ID
    AUTH0_CLIENT_SECRET     = var.AUTH0_CLIENT_SECRET
    AUTH0_M2M_CLIENT_ID     = var.AUTH0_M2M_CLIENT_ID
    AUTH0_M2M_CLIENT_SECRET = var.AUTH0_M2M_CLIENT_SECRET
    AUTH0_ADMIN_USER_ID     = var.AUTH0_ADMIN_USER_ID

    # GitHub (prefixed GH_ — `GITHUB_*` is reserved by Actions)
    GH_OWNER = var.GITHUB_OWNER
    GH_TOKEN = var.GITHUB_TOKEN
    GH_REPO  = var.GITHUB_REPO

    # OCI infrastructure outputs
    ARM_IP                = module.infra.instances["app"].public_ip
    VAULT_OCID            = module.infra.vault_id
    VAULT_KEY_ID          = module.infra.vault_key_id
    VAULT_CRYPTO_ENDPOINT = module.infra.vault_crypto_endpoint
    OCI_OS_NAMESPACE      = module.infra.os_namespace
    MAIN_DB_OCID          = module.infra.database_ids["main"]
  }
}

resource "github_actions_secret" "secrets" {
  for_each        = local.github_secrets
  repository      = data.github_repository.repo.name
  secret_name     = each.key
  plaintext_value = each.value
}
