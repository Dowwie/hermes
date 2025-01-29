import Config

config :logger, level: :warning

config :hermes, Hermes.Repo,
  username: "postgres",
  password: "postgres",
  database: "hermes",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 20


config :hermes, Hermes.Provider,
  api_clients: %{
    provider_sms: Hermes.Provider.Client.MockClient,
    provider_mms: Hermes.Provider.Client.MockClient,
    provider_email: Hermes.Provider.Client.MockClient
  }
