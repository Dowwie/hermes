defmodule HermesWeb.API.WebhookController do
  @moduledoc """
  Acts as a simple pass-through, quickly accepting valid JSON requests
  and forwarding them to the Producer for later processing.
  """
  use HermesWeb, :api_controller
  alias Hermes.Ingest.Producer
  require Logger

  @retry_after_ms 1000
  @channels Application.compile_env(:hermes, Hermes.Provider)[:channels] || %{}
  @channel_keys Map.keys(@channels)

  def action(conn, _params) do
    webhook_channel = action_name(conn)

    if Enum.member?(@channel_keys, webhook_channel) do
      params = Map.merge(conn.body_params, %{"channel" => webhook_channel})

      process_webhook(conn, params)
    else
      conn
      |> put_status(:not_found)
      |> json(%{})
    end
  end

  defp process_webhook(conn, params) do
    request_id = get_req_header(conn, "x-request-id") |> List.first() || ""
    Logger.metadata(request_id: request_id, channel: Map.get(params, :channel))

    case Producer.push(params) do
      :ok ->
        conn
        |> put_status(:accepted)
        |> put_resp_header("x-request-id", request_id)
        |> json(%{})

      {:error, :queue_full} ->
        Logger.warning("Queue is full. Dropping webhook.")

        conn
        |> put_status(:service_unavailable)
        |> put_resp_header("retry-after", to_string(@retry_after_ms))
        |> json(%{})

      {:error, reason} ->
        Logger.error("Failed to process webhook: #{inspect(reason)}")

        conn
        |> put_status(:internal_server_error)
        |> json(%{})
    end
  end
end
