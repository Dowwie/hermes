defmodule Hermes.Channel.SMS do
  @moduledoc """
  SMS Provider implementation
  (Provider would replaced by actual provider name such as SendGridSMS)
  """

  use Hermes.Provider
  use Ecto.Schema

  import Ecto.Changeset

  alias Hermes.Schema.NormalizedMessage

  embedded_schema do
    field :from, :string
    field :to, :string
    field :type, :string
    field :xillio_id, :string
    field :body, :string
    field :attachments, {:array, :string}
    field :timestamp, :utc_datetime
  end

  def validate_into(params) do
    %__MODULE__{}
    |> cast(params, [:from, :to, :type, :xillio_id, :body, :attachments, :timestamp])
    |> validate_required([:from, :to, :timestamp])
    |> validate_e164(:from)
    |> validate_e164(:to)
    |> validate_attachments()
    |> apply_action(:validate)
  end

  def into_message(validated) do
    %NormalizedMessage{
      channel: :provider_sms,
      from: validated.from,
      to: validated.to,
      xillio_id: validated.xillio_id,
      body: validated.body,
      attachments: validated.attachments || [],
      timestamp: validated.timestamp
    }
  end

  defp validate_e164(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      if value =~ ~r/^\+\d{1,15}$/, do: [], else: [{field, "invalid E.164 format"}]
    end)
  end

  defp validate_attachments(changeset) do
    validate_length(changeset, :attachments, max: 10)
  end
end
