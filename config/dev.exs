import Config

config :logger, level: :debug

config :hermes, HermesWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4003],
  code_reloader: true,
  debug_errors: false,
  secret_key_base: "8nH09tbXvhV1AigbaLztFKefh4bitcvyT/5m+2sTGCeooiy+UtWuVJ2EzubZZ6A8"

config :hermes, Hermes.Repo,
  username: "postgres",
  password: "postgres",
  database: "hermes",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 20


config :hermes, Hermes.Provider,
  api_clients: %{
    provider_sms: Hermes.Provider.Client.MockClient,
    provider_mms: Hermes.Provider.Client.MockClient,
    provider_email: Hermes.Provider.Client.MockClient
  }
