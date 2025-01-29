defmodule Hermes.Provider do
  @moduledoc """
  Provider facade and implementation support
  """
  require Logger
  alias Hermes.Schema.NormalizedMessage
  alias Broadway.Message, as: BroadwayMessage

  @providers Application.compile_env(:hermes, Hermes.Provider)[:channels] || %{}
  @api_clients Application.compile_env(:hermes, Hermes.Provider)[:api_clients] || %{}


  @doc """
  Builds a message using the specified channel.
  """
  def normalize_message(params) do
    channel_key = Map.get(params, "channel")

    case get_channel(channel_key) do
      {:ok, provider_mod} ->
        provider_mod.normalize_message(params)

      error ->
        Logger.error("Failed to normalize message: #{inspect(error)} - channel_key: #{inspect(channel_key)}")
        {:error, :channel_not_found}
        error
    end
  end

  @doc """
  Dispatches messages to third-party providers
  """
  def send_messages(messages) do
    Enum.each(messages, &send_message/1)
  end

  def send_message(%BroadwayMessage{data: %NormalizedMessage{} = message}) do
    case get_api_client(message.channel) do
      {:ok, client_mod} ->
        client_mod.send_message(message)

      error ->
        Logger.error("Failed to send message: #{inspect(error)} - message: #{inspect(message)}")
        {:error, :api_client_not_found}
        error
    end
  end

  defmacro __using__(_opts) do
    quote do
      def normalize_message(params) do
        with {:ok, validated} <- validate_into(params) do
          {:ok, into_message(validated)}
        end
      end

      # Default implementations that enforce the contract
      defp validate_into(_params) do
        raise "#{__MODULE__} must implement validate/1"
      end

      defp into_message(_validated) do
        raise "#{__MODULE__} must implement into_message/1"
      end

      defoverridable validate_into: 1, into_message: 1
    end
  end

  defp get_channel(channel_key) do
    case Map.fetch(@providers, channel_key) do
      {:ok, mod} -> {:ok, mod}
      :error -> {:error, :provider_not_found}
    end
  end

  defp get_api_client(channel) do
    case Map.fetch(@api_clients, channel) do
      {:ok, client_mod} ->
        {:ok, client_mod}

      :error ->
        Logger.error("No API client found for channel: #{inspect(channel)}")
        {:error, :api_client_not_found}
    end
  end
end
