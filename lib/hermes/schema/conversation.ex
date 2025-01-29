defmodule Hermes.Schema.Conversation do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "conversation" do
    field :ext_id, Ecto.UUID, autogenerate: true

    belongs_to :party_a, Hermes.Schema.Party
    belongs_to :party_b, Hermes.Schema.Party
    has_many :messages, Hermes.Schema.Message

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(conversation, attrs) do
    conversation
    |> cast(attrs, [:party_a_id, :party_b_id])
    |> validate_required([:party_a_id, :party_b_id])
    |> foreign_key_constraint(:party_a_id)
    |> foreign_key_constraint(:party_b_id)
    |> unique_constraint([:party_a_id, :party_b_id])
    |> check_constraint(:unique_party_pair, name: :unique_party_pair)
    |> validate_different_parties()
  end

  defp validate_different_parties(changeset) do
    party_a_id = get_field(changeset, :party_a_id)
    party_b_id = get_field(changeset, :party_b_id)

    if party_a_id && party_b_id && party_a_id >= party_b_id do
      add_error(changeset, :party_b_id, "must be different than party_a_id")
    else
      changeset
    end
  end
end
