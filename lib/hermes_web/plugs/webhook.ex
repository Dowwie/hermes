defmodule HermesWeb.Auth.Webhook do
  @moduledoc false

  alias Plug.Conn

  require Logger

  @behaviour Plug

  @config Application.compile_env(:hermes, __MODULE__) || %{}

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    with [signature] <- Conn.get_req_header(conn, "x-provider-signature-256") do
      secret = @config |> Keyword.fetch!(:provider_webhook_secret)

      payload = conn.assigns.raw_body

      "sha256=" <> provided_signature = signature


      if signature_is_valid?(secret, payload, provided_signature) do
        conn
      else
        Logger.error("Webhook signature auth error - #{inspect(payload)}")

        error_with_reason(conn, "Invalid signature")
      end
    else
      [] ->
        error_with_reason(
          conn,
          "Missing headers"
        )
    end
  end

  defp signature_is_valid?(secret, payload, provided_signature) do
    expected_signature = :crypto.mac(:hmac, :sha256, secret, payload) |> Base.encode16(case: :lower)

    Plug.Crypto.secure_compare(provided_signature, expected_signature)
  end

  defp error_with_reason(conn, reason) do
    body = %{
      errors: %{
        detail: reason
      }
    }

    conn
    |> Conn.put_resp_content_type("application/json")
    |> Conn.send_resp(:unauthorized, Jason.encode!(body))
    |> Conn.halt()
  end
end
