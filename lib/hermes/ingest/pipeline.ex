defmodule Hermes.Ingest.Pipeline do
  @moduledoc """
  Ingestion pipeline for webhook messages
  """

  use Broadway

  alias Hermes.ConversationContext
  alias Hermes.Provider

  @producer_max_buffer 100_000
  @batch_size 100
  @batch_timeout 50

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)

    Broadway.start_link(__MODULE__,
      name: name,
      producer: [
        module: {
          Hermes.Ingest.Producer,
          max_buffer: @producer_max_buffer
        },
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: System.schedulers_online(),
          max_demand: 200
        ]
      ],
      batchers: [
        default: [
          concurrency: 4,
          batch_size: @batch_size,
          batch_timeout: @batch_timeout
        ]
      ]
    )
  end

  def handle_message(_processor, message, _context) do
    with {:ok, validated_message} <- Hermes.Provider.normalize_message(message.data) do
      message
      |> Broadway.Message.put_data(validated_message)
      |> Broadway.Message.put_batcher(:default)
    else
      {:error, reason} ->
        Broadway.Message.failed(message, reason)
    end
  end

  def handle_batch(_batcher, messages, _batch_info, _context) do
    ConversationContext.save_many(messages)
    Provider.send_messages(messages)

    messages
  end
end
