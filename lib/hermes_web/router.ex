defmodule HermesWeb.Router do
  use Phoenix.Router
  import Plug.Conn

  pipeline :webhooks do
    # plug :enforce_json_content_type
    # plug :verify_provider_signature
    plug :accepts, ["json"]
  end

  scope "/api/webhooks", HermesWeb.API do
    pipe_through :webhooks

    post "/sms", WebhookController, :sms
    post "/email", WebhookController, :email
  end
end
