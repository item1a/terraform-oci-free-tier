# --- Auth0: SPA + M2M clients, API resource server, roles, post-login JWT action ---
#
# The caller configures the auth0 provider:
#   provider "auth0" {
#     domain        = var.AUTH0_DOMAIN
#     client_id     = var.AUTH0_M2M_CLIENT_ID
#     client_secret = var.AUTH0_M2M_CLIENT_SECRET
#   }

resource "auth0_client" "spa" {
  name            = var.auth0_spa_name
  app_type        = "spa"
  is_first_party  = true
  oidc_conformant = true

  callbacks           = var.auth0_callback_urls
  allowed_logout_urls = var.auth0_callback_urls
  web_origins         = var.auth0_callback_urls

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

resource "auth0_client" "m2m" {
  name            = var.auth0_m2m_name
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

resource "auth0_resource_server" "api" {
  name                                            = var.auth0_api_name
  identifier                                      = var.auth0_api_audience
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

resource "auth0_action" "add_info_to_token" {
  name    = "Add User Info to Tokens"
  runtime = "node18"
  deploy  = true
  code    = <<-EOT
    exports.onExecutePostLogin = async (event, api) => {
      if (!event.user.email_verified) {
        api.access.deny('Please verify your email before logging in.');
      }
      const namespace = '${var.auth0_jwt_namespace}';

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

resource "auth0_user_roles" "admin_assignment" {
  count   = var.auth0_admin_user_id != "" ? 1 : 0
  user_id = var.auth0_admin_user_id
  roles   = [auth0_role.admin.id]
}
