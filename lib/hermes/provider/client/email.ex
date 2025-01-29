defmodule Hermes.Provider.Client.EmailClient do

  @behaviour Hermes.Provider.Client

  alias Hermes.Schema.NormalizedMessage
  alias Req.Request
  alias Req.Response

  require Logger

  @config Application.compile_env(:hermes, __MODULE__) || %{}
  @base_url Map.get(@config, :base_url)
  @api_key Map.get(@config, :api_key)
  @email_endpoint "/api/email"

  @impl true
  def send_message(%NormalizedMessage{} = message) do
    client = build_client()

    message
    |> build_payload()
    |> do_send_message(client)
  end

  defp build_client do
    headers = [
      {"Authorization", "Bearer #{@api_key}"},
      {"Content-Type", "application/json"}
    ]

    Req.new(
      base_url: @base_url,
      max_retries: 3
    )
    |> Request.put_headers(headers)
  end

  defp do_send_message(payload, client) do
    case Req.post(client, url: @email_endpoint, json: payload) do
      {:ok, %Response{status: status} = response} when status in 200..299 ->
        Logger.info("Successfully sent email: #{inspect(payload)}")
        {:ok, response.body}

      {:ok, %Response{status: status} = response} ->
        Logger.error("Email provider error: #{status} - #{inspect(response.body)}")
        {:error, :provider_error}

      {:error, exception} = error ->
        Logger.error("Failed to send email: #{inspect(exception)}")
        error
    end
  end

  defp build_payload(%NormalizedMessage{} = message) do
    %{
      from: message.from,
      to: message.to,
      body: message.body,
      attachments: message.attachments,
      timestamp: message.timestamp
    }
  end
end
