defmodule Hermes.Schema.Attachment do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "attachment" do
    field :ext_id, Ecto.UUID, autogenerate: true
    field :url, :string

    belongs_to :message, Hermes.Schema.Message

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(attachment, attrs) do
    attachment
    |> cast(attrs, [:url, :message_id])
    |> validate_required([:url, :message_id])
    |> foreign_key_constraint(:message_id)
  end
end
