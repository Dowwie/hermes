defmodule HermesWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :hermes

  plug Plug.Parsers,
    parsers: [:json],
    json_decoder: Phoenix.json_library(),
    body_reader: {HermesWeb.Plugs.CacheBodyReader, :read_body, []},
    pass: []

  plug Plug.RequestId
  plug Plug.MethodOverride
  plug Plug.Head
  plug HermesWeb.Router
end
