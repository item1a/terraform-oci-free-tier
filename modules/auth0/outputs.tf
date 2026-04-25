output "spa_client_id" {
  value     = auth0_client.spa.id
  sensitive = true
}

output "m2m_client_id" {
  value     = auth0_client.m2m.id
  sensitive = true
}

output "api_audience" {
  value = auth0_resource_server.api.identifier
}
