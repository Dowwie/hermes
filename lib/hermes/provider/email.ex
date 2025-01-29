defmodule Hermes.Channel.Email do
  @moduledoc """
  Email Provider implementation
  (Provider would replaced by actual provider name such as MailPlusEmail)
  """

  use Hermes.Provider
  use Ecto.Schema

  import Ecto.Changeset

  alias Hermes.Schema.NormalizedMessage

  embedded_schema do
    field :from, :string
    field :to, :string
    field :xillio_id, :string
    field :body, :string
    field :attachments, {:array, :string}
    field :timestamp, :utc_datetime
  end

  defp validate_into(params) do
    %__MODULE__{}
    |> cast(params, [:from, :to, :xillio_id, :body, :attachments, :timestamp])
    |> validate_required([:from, :to, :timestamp])
    |> validate_email(:from)
    |> validate_email(:to)
    |> validate_attachments()
    |> apply_action(:validate)
  end

  defp into_message(validated) do
    %NormalizedMessage{
      channel: :provider_email,
      from: String.downcase(validated.from),
      to: String.downcase(validated.to),
      xillio_id: validated.xillio_id,
      body: validated.body,
      attachments: validated.attachments || [],
      timestamp: validated.timestamp
    }
  end

  defp validate_email(changeset, field) do
    validate_change(changeset, field, fn _, value ->
      if value =~ ~r/^[^\s]+@[^\s]+$/, do: [], else: [{field, "invalid email format"}]
    end)
  end

  defp validate_attachments(changeset) do
    validate_length(changeset, :attachments, max: 25)
  end
end
