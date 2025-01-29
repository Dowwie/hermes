defmodule Hermes.Schema.Party do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "party" do
    field :ext_id, Ecto.UUID, autogenerate: true
    field :party_name, :string
    field :email, :string
    field :phone_e164, :string

    has_many :sent_messages, Hermes.Schema.Message, foreign_key: :sender_id
    has_many :received_messages, Hermes.Schema.Message, foreign_key: :recipient_id

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(party, attrs) do
    party
    |> cast(attrs, [:party_name, :email, :phone_e164])
  end
end
