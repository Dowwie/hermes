defmodule Hermes.Schema.NormalizedMessage do
  @moduledoc """
  Standardized message structure for all processed communications.
  """

  @derive {Jason.Encoder, only: [:channel, :from, :to, :xillio_id, :body, :attachments, :timestamp]}
  defstruct [
    :channel,
    :from,
    :to,
    :xillio_id,
    :body,
    :attachments,
    :timestamp
  ]

  @type t :: %__MODULE__{
          channel: :provider_sms | :provider_mms | :provider_email,
          from: String.t(),
          to: String.t(),
          xillio_id: String.t(),
          body: String.t() | nil,
          attachments: [String.t()],
          timestamp: DateTime.t()
        }
end
