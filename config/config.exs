import Config

config :logger,
  level: :info,
  backends: [:console]

config :logger_json, :backend, json_encoder: Jason, metadata: :all

config :hermes, ecto_repos: [Hermes.Repo]

config :hermes, HermesWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [json: HermesWeb.ErrorJSON],
    layout: false
  ]

config :hermes, Hermes.Provider,
  channels: %{
    mms: Hermes.Channel.SMS,
    sms: Hermes.Channel.SMS,
    email: Hermes.Channel.Email
  }

config :hermes, :webhooks,
  sms: System.get_env("WEBHOOK_SMS_SECRET"),
  email: System.get_env("WEBHOOK_EMAIL_SECRET")

import_config "#{config_env()}.exs"
