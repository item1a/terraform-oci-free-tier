# Example: full deployment with all addon modules

A complete configuration that wires in every optional addon: Cloudflare LB + DNS + SSL, Auth0 SPA stack, and GitHub Actions secret sync.

In Path B (the current shape), addons are separate top-level module calls — the consumer picks the ones they want, configures the matching providers, and threads core outputs into addon inputs. There are no `enable_*` flags anymore.

- **`module "core"`** — VCN, ARM instances, ATP database, Vault, Object Storage bucket. Always invoked.
- **`module "cloudflare"`** (`//modules/cloudflare`) — OCI Load Balancer fronted by Cloudflare with origin CA cert, NSG restricted to Cloudflare IPv4/IPv6 ranges, DNS records, strict SSL.
- **`module "auth0"`** (`//modules/auth0`) — SPA + M2M clients, API resource server with admin scope, admin/user roles, post-login action injecting email/name/roles into JWTs, optional admin role auto-assignment.
- **`module "github_secrets"`** (`//modules/github`) — syncs OCI auth, SSH keys, Cloudflare creds, Auth0 creds, and infrastructure outputs (per-instance `<NAME>_IP`, per-database `<KEY>_DB_OCID`, vault, OS namespace) into the GitHub repo's Actions secrets. Pass `extra_secrets = {}` for project-specific extras.

## Prerequisites

In addition to the [module prerequisites](../../README.md#prerequisites):

- An **Auth0 tenant** with an M2M application authorized for the Auth0 Management API (scopes: `read:roles`, `create:roles`, `update:roles`, `read:actions`, `create:actions`, `update:actions`, `read:resource_servers`, `create:resource_servers`, `update:resource_servers`, `read:role_members`, `create:role_members`)
- A **Cloudflare API token** with permission to manage your zone (DNS records, origin CA, zone settings)
- A **GitHub personal access token** with `repo` scope

## Usage

```bash
cd examples/with-auth0-and-github
cp terraform.tfvars.example terraform.tfvars
# Fill in OCI, Cloudflare, GitHub, and Auth0 credentials
terraform init
terraform apply
```

## What you get afterward

- An ARM VM behind a Cloudflare-fronted LB with strict SSL, on a real domain
- An ATP database with auto-generated passwords stored in Vault
- An Auth0 SPA client + M2M client + API resource server + admin/user roles + post-login JWT action
- Your GitHub repo has every CI/CD secret it needs:
  - `OCI_*` (auth, region, namespace, tenancy)
  - `SSH_PRIVATE_KEY`, `SSH_PUBLIC_KEY`, `IP_ADDRESS`
  - `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ZONE_ID`, `DOMAIN_NAME`
  - `AUTH0_DOMAIN`, `AUTH0_CLIENT_ID/SECRET`, `AUTH0_M2M_CLIENT_ID/SECRET`, `AUTH0_ADMIN_USER_ID`
  - `GH_OWNER`, `GH_REPO`
  - `<NAME>_IP` per instance (e.g., `APP_IP`)
  - `<KEY>_DB_OCID` per database (e.g., `MAIN_DB_OCID`)
  - `VAULT_OCID`, `VAULT_KEY_ID`, `VAULT_CRYPTO_ENDPOINT`

To auto-assign admin on first login: log in once, find your `user_id` in Auth0 Dashboard > User Management > Users, set `AUTH0_ADMIN_USER_ID` in `terraform.tfvars`, then `terraform apply` again.

## Picking only some addons

For a slimmer setup, just delete the addon module calls you don't need from `main.tf`, plus the matching `provider` block and `required_providers` entry. Examples:

- **Core only** — keep `module "core"`. Delete the cloudflare/auth0/github_secrets module blocks, their providers, and their entries in `required_providers`. The consumer's required_providers shrinks to just `oci` and `random`.
- **Core + Cloudflare** — keep `module "core"` + `module "cloudflare"` + the `oci` / `cloudflare` / `tls` / `random` providers. Drop auth0 + github_secrets.
- **Core + GitHub** (CI sync without LB or Auth0) — keep `module "core"` + `module "github_secrets"` + the `oci` / `random` / `github` providers. The github addon doesn't require cloudflare/auth0 to be present; it just won't push their secrets unless the relevant input vars are set.

## Notes

- `AUTH0_JWT_NAMESPACE` must match what your backend reads when validating JWTs (typically `https://<your-domain>`). The post-login action attaches `<namespace>/email`, `<namespace>/name`, and `<namespace>/roles` to access and ID tokens.
- `GITHUB_*` is a reserved prefix in Actions, so the GitHub-related secrets use the `GH_` prefix instead.
- `terraform destroy` removes every secret managed by the github addon. Run `terraform apply` before pushing if you've just destroyed.
