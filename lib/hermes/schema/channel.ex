defmodule Hermes.Schema.Channel do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "channel" do
    field :ext_id, Ecto.UUID, autogenerate: true
    field :channel_name, :string

    belongs_to :provider, Hermes.Schema.Provider
    has_many :messages, Hermes.Schema.Message

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(channel, attrs) do
    channel
    |> cast(attrs, [:channel_name, :provider_id])
    |> validate_required([:channel_name, :provider_id])
    |> validate_length(:channel_name, max: 30)
    |> foreign_key_constraint(:provider_id)
    |> unique_constraint([:provider_id, :channel_name], name: :unique_channel)
  end
end
