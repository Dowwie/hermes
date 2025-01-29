defmodule Hermes.Provider.Client do
  @moduledoc false

  alias Hermes.Schema.NormalizedMessage

  @callback send_message(NormalizedMessage.t()) :: {:ok, map()} | {:error, any()}
end
