# Example: terraform-oci-free-tier + Auth0 + GitHub Actions secret sync.
#
# Demonstrates how to wire Auth0 and the GitHub provider alongside the module
# call. Auth0 and GitHub resources live OUTSIDE the module — the module owns
# the OCI infrastructure, this directory wires up everything else.
#
# Replace `example-app` and the backend bucket/namespace with your own.

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">= 7.12.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
    auth0 = {
      source  = "auth0/auth0"
      version = ">= 1.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
  }

  # Optional remote state. Create the bucket once, then uncomment.
  # backend "oci" {
  #   bucket    = "terraform-state"
  #   namespace = "YOUR_OS_NAMESPACE"
  #   key       = "example-app/terraform.tfstate"
  # }
}

provider "oci" {
  tenancy_ocid = var.TENANCY_OCID
  user_ocid    = var.USER_OCID
  fingerprint  = var.FINGERPRINT
  private_key  = local.oci_private_key
  region       = var.REGION
}

provider "cloudflare" {
  api_token = var.CLOUDFLARE_API_TOKEN
}

provider "github" {
  owner = var.GITHUB_OWNER
  token = var.GITHUB_TOKEN
}

provider "auth0" {
  domain        = var.AUTH0_DOMAIN
  client_id     = var.AUTH0_M2M_CLIENT_ID
  client_secret = var.AUTH0_M2M_CLIENT_SECRET
}

module "infra" {
  source = "../.."

  tenancy_ocid   = var.TENANCY_OCID
  region         = var.REGION
  ssh_public_key = local.ssh_public_key
  project_name   = "example-app"

  instances = {
    app = {
      ocpus           = 4
      memory_gb       = 24
      block_volume_gb = 50
      behind_lb       = true
    }
  }

  databases = {
    main = { display_name = "MainDB", db_name = "MAINDB" }
  }

  bucket_name = "example-app-backups"

  enable_cloudflare    = true
  cloudflare_api_token = var.CLOUDFLARE_API_TOKEN
  cloudflare_zone_id   = var.CLOUDFLARE_ZONE_ID
  domain_name          = var.DOMAIN_NAME
  dns_records          = [var.DOMAIN_NAME, "app"]
}
