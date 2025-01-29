defmodule Hermes.Schema.Provider do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :id, autogenerate: true}
  schema "provider" do
    field :ext_id, Ecto.UUID, autogenerate: true
    field :provider_name, :string
    field :service_url, :string

    has_many :channels, Hermes.Schema.Channel

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(provider, attrs) do
    provider
    |> cast(attrs, [:provider_name, :service_url])
    |> validate_required([:provider_name, :service_url])
    |> unique_constraint([:provider_name], name: :unique_provider_name)
  end
end
