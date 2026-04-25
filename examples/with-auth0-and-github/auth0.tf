# Auth0 resources: SPA + M2M clients, API resource server with admin scope,
# admin/user roles, post-login action injecting email/name/roles into JWT,
# optional admin auto-assignment.

# --- SPA client (frontend) ---

resource "auth0_client" "spa" {
  name            = "Example SPA"
  app_type        = "spa"
  is_first_party  = true
  oidc_conformant = true

  callbacks           = var.AUTH0_CALLBACK_URLS
  allowed_logout_urls = var.AUTH0_CALLBACK_URLS
  web_origins         = var.AUTH0_CALLBACK_URLS

  grant_types = ["authorization_code", "implicit", "refresh_token"]

  jwt_configuration {
    alg = "RS256"
  }

  refresh_token {
    rotation_type       = "rotating"
    expiration_type     = "expiring"
    token_lifetime      = 2592000
    idle_token_lifetime = 1296000
  }

  lifecycle {
    ignore_changes = [description]
  }
}

resource "auth0_client_credentials" "spa_credentials" {
  client_id             = auth0_client.spa.id
  authentication_method = "none"
}

# --- M2M client (used by the Terraform Auth0 provider itself) ---

resource "auth0_client" "m2m" {
  name            = "Example Terraform (M2M)"
  app_type        = "non_interactive"
  is_first_party  = true
  oidc_conformant = true

  grant_types = ["client_credentials"]

  lifecycle {
    ignore_changes = [description]
  }
}

resource "auth0_client_credentials" "m2m_credentials" {
  client_id             = auth0_client.m2m.id
  authentication_method = "client_secret_post"
}

# --- API resource server ---

resource "auth0_resource_server" "api" {
  name                                            = "Example API"
  identifier                                      = var.AUTH0_API_AUDIENCE
  signing_alg                                     = "RS256"
  token_lifetime                                  = 86400
  skip_consent_for_verifiable_first_party_clients = true
  enforce_policies                                = true
  token_dialect                                   = "access_token_authz"
}

resource "auth0_resource_server_scopes" "api_scopes" {
  resource_server_identifier = auth0_resource_server.api.identifier

  scopes {
    name        = "admin:access"
    description = "Full admin access"
  }
}

# --- Roles ---

resource "auth0_role" "admin" {
  name        = "admin"
  description = "Platform administrator"
}

resource "auth0_role" "user" {
  name        = "user"
  description = "Standard user"
}

resource "auth0_role_permissions" "admin_permissions" {
  role_id = auth0_role.admin.id

  permissions {
    resource_server_identifier = auth0_resource_server.api.identifier
    name                       = "admin:access"
  }
}

# --- Post-login action: require verified email, inject claims ---

resource "auth0_action" "add_info_to_token" {
  name    = "Add User Info to Tokens"
  runtime = "node18"
  deploy  = true
  code    = <<-EOT
    exports.onExecutePostLogin = async (event, api) => {
      if (!event.user.email_verified) {
        api.access.deny('Please verify your email before logging in.');
      }
      const namespace = '${var.AUTH0_JWT_NAMESPACE}';

      api.accessToken.setCustomClaim(`$${namespace}/email`, event.user.email);
      api.idToken.setCustomClaim(`$${namespace}/email`, event.user.email);

      if (event.user.name) {
        api.accessToken.setCustomClaim(`$${namespace}/name`, event.user.name);
        api.idToken.setCustomClaim(`$${namespace}/name`, event.user.name);
      }

      if (event.authorization) {
        api.accessToken.setCustomClaim(`$${namespace}/roles`, event.authorization.roles);
        api.idToken.setCustomClaim(`$${namespace}/roles`, event.authorization.roles);
      }
    };
  EOT

  supported_triggers {
    id      = "post-login"
    version = "v3"
  }
}

resource "auth0_trigger_actions" "post_login" {
  trigger = "post-login"

  actions {
    id           = auth0_action.add_info_to_token.id
    display_name = auth0_action.add_info_to_token.name
  }
}

# --- Optional: auto-assign admin role to one user ---

resource "auth0_user_roles" "admin_assignment" {
  count   = var.AUTH0_ADMIN_USER_ID != "" ? 1 : 0
  user_id = var.AUTH0_ADMIN_USER_ID
  roles   = [auth0_role.admin.id]
}
