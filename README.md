# terraform-oci-free-tier

Reusable Terraform module for OCI Always Free tier infrastructure. Deploys an ARM compute instance, up to 2 Oracle Autonomous Databases, OCI Vault KMS, and optionally a load balancer with Cloudflare SSL.

## What it creates

- **Networking** — VCN, public/private subnets, internet + service gateways, route tables
- **Compute** — ARM A1.Flex instance (4 OCPU / 24GB default) with cloud-init, optional block volume
- **Database** — 0-2 ATP free-tier instances (23ai) with auto-generated passwords stored in Vault
- **Vault** — OCI Vault + AES-256 master key + dynamic group + IAM policies for instance principal auth
- **Object Storage** — Optional backup bucket with prevent_destroy lifecycle
- **Security** — Public/private security lists, SSH access, app port ingress
- **Quota** — Free tier enforcement (4 ARM OCPUs, 2 AMD micros, 200GB storage)
- **Cloudflare** (optional) — Load balancer, origin CA certificate, DNS records, strict SSL

## Usage

```hcl
module "infra" {
  source = "github.com/MMJLee/terraform-oci-free-tier"

  tenancy_ocid = var.TENANCY_OCID
  region       = var.REGION

  # Compute
  ssh_public_key   = file("./oci_public_key.pub")
  project_name     = "myapp"
  extra_packages   = ["nodejs:20"]
  extra_cloud_init = "npm install -g some-cli || true"

  # Databases (0-2)
  databases = {
    main = { display_name = "MainDB", db_name = "MAINDB" }
  }

  # Backup bucket
  backup_bucket_name = "myapp-backups"

  # Cloudflare (optional)
  enable_cloudflare    = true
  cloudflare_api_token = var.CLOUDFLARE_API_TOKEN
  cloudflare_zone_id   = var.CLOUDFLARE_ZONE_ID
  domain_name          = "example.com"
  dns_records          = ["example.com", "app"]
}
```

## Providers

The calling module must configure these providers:

```hcl
provider "oci" {
  tenancy_ocid = var.TENANCY_OCID
  user_ocid    = var.USER_OCID
  fingerprint  = var.FINGERPRINT
  private_key  = file(var.OCI_PRIVATE_KEY_PATH)
  region       = var.REGION
}

# Only needed if enable_cloudflare = true
provider "cloudflare" {
  api_token = var.CLOUDFLARE_API_TOKEN
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `tenancy_ocid` | string | required | OCI tenancy OCID |
| `region` | string | required | OCI region |
| `ssh_public_key` | string | required | SSH public key for instance access |
| `project_name` | string | `"app"` | Used in resource display names |
| `arm_shape` | string | `"VM.Standard.A1.Flex"` | Compute shape |
| `arm_ocpus` | number | `4` | ARM OCPUs |
| `arm_memory_gb` | number | `24` | ARM memory in GB |
| `boot_volume_size_gb` | number | `50` | Boot volume size |
| `block_volume_size_gb` | number | `50` | Block volume size (0 to skip) |
| `app_port` | number | `8080` | Application port |
| `app_user` | string | `"opc"` | OS user for the app |
| `workspace_path` | string | `"/var/workspace"` | Block volume mount path |
| `extra_packages` | list(string) | `[]` | Additional dnf packages |
| `extra_cloud_init` | string | `""` | Additional cloud-init commands |
| `databases` | map(object) | `{}` | ATP databases to create |
| `backup_bucket_name` | string | `""` | Backup bucket name (empty to skip) |
| `enable_cloudflare` | bool | `false` | Enable LB + Cloudflare SSL |
| `cloudflare_api_token` | string | `""` | Cloudflare API token |
| `cloudflare_zone_id` | string | `""` | Cloudflare zone ID |
| `domain_name` | string | `""` | Domain for SSL cert |
| `dns_records` | list(string) | `[]` | DNS A records to create |

## Outputs

| Name | Description |
|------|-------------|
| `instance_public_ip` | ARM instance public IP |
| `instance_private_ip` | ARM instance private IP |
| `instance_id` | ARM instance OCID |
| `ssh_command` | SSH command to connect |
| `vcn_id` | VCN OCID |
| `public_subnet_id` | Public subnet OCID |
| `private_subnet_id` | Private subnet OCID |
| `load_balancer_ip` | LB public IP (null if Cloudflare disabled) |
| `database_ids` | Map of database OCIDs |
| `database_admin_passwords` | Map of DB admin passwords (sensitive) |
| `database_wallet_passwords` | Map of DB wallet passwords (sensitive) |
| `database_connection_urls` | Map of DB connection URLs |
| `db_region_host` | ATP host with port |
| `vault_id` | Vault OCID |
| `vault_crypto_endpoint` | Vault crypto endpoint |
| `vault_key_id` | Master encryption key OCID |
| `os_namespace` | Object Storage namespace |

## Free Tier Limits

| Resource | Spec |
|----------|------|
| ARM Instance | VM.Standard.A1.Flex, 4 OCPU, 24GB |
| Boot + Block Volume | 200GB total |
| Load Balancer | 1 flexible, 10 Mbps |
| Autonomous DB | 2 instances, 20GB each |
| OCI Vault | 20 key versions, 150 secrets |
| Object Storage | 10GB |
