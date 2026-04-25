# Example: with Auth0 + GitHub Actions secret sync

A complete, working configuration that wires the `terraform-oci-free-tier` module together with:

- **Auth0** — SPA + M2M clients, API resource server with admin scope, admin/user roles, a post-login action that injects email/name/roles into the JWT, and optional auto-assignment of the admin role to one user
- **GitHub Actions secret sync** — pushes every credential and OCI infrastructure OCID into your GitHub repo's Actions secrets so CI/CD has everything it needs after `terraform apply`

These resources intentionally live **outside** the module — the module owns OCI infrastructure, this directory wires up everything else.

## Prerequisites

In addition to the [module prerequisites](../../README.md#prerequisites):

- An **Auth0 tenant** with an M2M application authorized for the Auth0 Management API (scopes: `read:roles`, `create:roles`, `update:roles`, `read:actions`, `create:actions`, `update:actions`, `read:resource_servers`, `create:resource_servers`, `update:resource_servers`, `read:role_members`, `create:role_members`)
- A **GitHub personal access token** with `repo` scope

## Usage

```bash
cd examples/with-auth0-and-github
cp terraform.tfvars.example terraform.tfvars
# Fill in OCI, Cloudflare, GitHub, and Auth0 credentials
terraform init
terraform apply
```

After applying:

- Your GitHub repo has every CI/CD secret it needs (OCI auth, SSH, Cloudflare, Auth0, ARM IP, vault OCIDs, DB OCIDs)
- Auth0 has a SPA client, an M2M client, an API resource server, admin/user roles, and a post-login action

To auto-assign the admin role on first login: log in once, find your `user_id` in Auth0 Dashboard > User Management > Users, set `AUTH0_ADMIN_USER_ID` in `terraform.tfvars`, then `terraform apply` again.

## Notes

- The `AUTH0_JWT_NAMESPACE` you set must match what your backend reads when validating JWTs (typically `https://<your-domain>`). The post-login action attaches `<namespace>/email`, `<namespace>/name`, and `<namespace>/roles` to access and ID tokens.
- The `github.tf` `github_secrets` map is intentionally explicit — add or remove entries to match what your workflow consumes. `GITHUB_*` is a reserved prefix in Actions, so the GitHub-related secrets use the `GH_` prefix instead.
- `terraform destroy` removes every secret managed by `github_actions_secret`. Run `terraform apply` before pushing to `main` if you've just destroyed.
