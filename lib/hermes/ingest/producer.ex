defmodule Hermes.Ingest.Producer do
  @moduledoc """
  A Broadway producer queue for message ingestion
  """

  use GenStage
  require Logger
  alias Broadway.Message

  @behaviour Broadway.Producer

  @default_producer_name Hermes.Ingest.Pipeline.Broadway.Producer_0
  @default_max_buffer 100_000

  @type producer_state :: %{
          queue: :queue.queue(),
          max_buffer: non_neg_integer(),
          pending_demand: non_neg_integer()
        }

  @impl true
  def init(opts) do
    max_buffer = Keyword.get(opts, :max_buffer, @default_max_buffer)

    initial_state = %{
      queue: :queue.new(),
      max_buffer: max_buffer,
      pending_demand: 0
    }

    {:producer, initial_state}
  end

  def push(item) do
    GenStage.call(@default_producer_name, {:push, item})
  end

  def get_buffer_info do
    GenStage.call(@default_producer_name, :get_buffer_info)
  end

  def set_max_buffer(new_size) when is_integer(new_size) and new_size >= 0 do
    GenStage.call(@default_producer_name, {:set_max_buffer, new_size})
  end

  @impl true
  def handle_call({:push, item}, _from, %{queue: queue, max_buffer: max_buffer, pending_demand: pending_demand} = state) do
    if :queue.len(queue) < max_buffer do
      Logger.debug("[Producer] Pushing item: #{inspect(item)}")

      if pending_demand > 0 do
        message = into_broadway_message(item)
        Logger.debug("[Producer] Dispatching item immediately due to pending demand")
        {:reply, :ok, [message], %{state | pending_demand: pending_demand - 1}}
      else
        new_queue = :queue.in(item, queue)
        Logger.debug("[Producer] Item added to queue. Queue size: #{:queue.len(new_queue)}")
        {:reply, :ok, [], %{state | queue: new_queue}}
      end
    else
      Logger.warning("[Producer] Queue full (size: #{max_buffer}), dropping message")
      {:reply, {:error, :queue_full}, [], state}
    end
  end

  def handle_call(:get_buffer_info, _from, %{queue: queue, max_buffer: max_buffer} = state) do
    current_size = :queue.len(queue)
    utilization = if max_buffer > 0, do: Float.round(current_size / max_buffer, 4), else: 0.0

    buffer_info = %{
      max_buffer: max_buffer,
      current_buffer_size: current_size,
      utilization: utilization
    }

    {:reply, buffer_info, [], state}
  end

  def handle_call({:set_max_buffer, new_size}, _from, state) do
    Logger.info("[Producer] Updating max buffer size to #{new_size}")
    {:reply, :ok, [], %{state | max_buffer: new_size}}
  end

  @impl true
  def handle_demand(demand, %{queue: queue, pending_demand: pending_demand} = state) when demand > 0 do
    Logger.debug("[Producer] Received demand for #{demand} items")
    {messages, new_queue} = take_from_queue(queue, demand)
    messages_count = length(messages)
    new_pending_demand = pending_demand + (demand - messages_count)

    if messages_count > 0 do
      Logger.debug("[Producer] Dispatching #{messages_count} messages")
    end

    if new_pending_demand > 0 do
      Logger.debug("[Producer] Storing pending demand: #{new_pending_demand}")
    end

    {:noreply, messages, %{state | queue: new_queue, pending_demand: new_pending_demand}}
  end

  defp take_from_queue(queue, demand) do
    take_from_queue(queue, demand, [])
  end

  defp take_from_queue(queue, 0, acc), do: {Enum.reverse(acc), queue}

  defp take_from_queue(queue, demand, acc) do
    case :queue.out(queue) do
      {{:value, item}, new_queue} ->
        Logger.debug("[Producer] Taking item from queue: #{inspect(item)}")
        message = into_broadway_message(item)
        take_from_queue(new_queue, demand - 1, [message | acc])

      {:empty, queue} ->
        Logger.debug("[Producer] Queue is empty")
        {Enum.reverse(acc), queue}
    end
  end

  defp into_broadway_message(item) do
    %Message{
      data: item,
      acknowledger: {Broadway.NoopAcknowledger, nil, nil}
    }
  end
end
