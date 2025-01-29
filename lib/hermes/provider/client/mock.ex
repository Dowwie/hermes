defmodule Hermes.Provider.Client.MockClient do
  @moduledoc false
  @behaviour Hermes.Provider.Client

  require Logger
  alias Hermes.Schema.NormalizedMessage

  @impl true
  def send_message(%NormalizedMessage{} = message) do
    Logger.info("MOCK API CLIENT: sending message: #{inspect(message)}")

    {:ok, %{}}
  end
end
