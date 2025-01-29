import Config

config :logger, level: :debug

config :logger, :default_handler, formatter: {LoggerJSON.Formatters.Basic, [metadata: {:all_except, [:conn]}]}


config :hermes, Hermes.Provider,
  api_clients: %{
    provider_sms: Hermes.Provider.Client.SMSClient,
    provider_mms: Hermes.Provider.Client.SMSClient,
    provider_email: Hermes.Provider.Client.EmailClient
  }
