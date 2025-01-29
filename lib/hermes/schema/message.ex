defmodule Hermes.Schema.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "message" do
    field :ext_id, Ecto.UUID, autogenerate: true
    field :body, :string
    field :sent_at, :utc_datetime_usec

    belongs_to :conversation, Hermes.Schema.Conversation
    belongs_to :channel, Hermes.Schema.Channel
    belongs_to :sender, Hermes.Schema.Party
    belongs_to :recipient, Hermes.Schema.Party
    has_many :attachments, Hermes.Schema.Attachment

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [
      :body,
      :sent_at,
      :conversation_id,
      :channel_id,
      :sender_id,
      :recipient_id
    ])
    |> validate_required([:sent_at, :conversation_id, :channel_id, :sender_id, :recipient_id])
    |> foreign_key_constraint(:conversation_id)
    |> foreign_key_constraint(:channel_id)
    |> foreign_key_constraint(:sender_id)
    |> foreign_key_constraint(:recipient_id)
  end
end
