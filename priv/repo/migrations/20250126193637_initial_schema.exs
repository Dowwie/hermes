defmodule Hermes.Repo.Migrations.InitialSchema do
  use Ecto.Migration

  def change do
    create table(:party, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :ext_id, :uuid, null: false, default: fragment("gen_random_uuid()")
      add :party_name, :text
      add :email, :text
      add :phone_e164, :string, size: 30

      timestamps(type: :utc_datetime_usec)
    end

    create index(:party, [:ext_id])
    create unique_index(:party, [:email], where: "email IS NOT NULL")
    create unique_index(:party, [:phone_e164], where: "phone_e164 IS NOT NULL")


    create table(:provider, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :ext_id, :uuid, null: false, default: fragment("gen_random_uuid()")
      add :provider_name, :text, null: false
      add :service_url, :text, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:provider, [:provider_name], name: :unique_provider_name)
    create index(:provider, [:ext_id])

    create table(:channel, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :ext_id, :uuid, null: false, default: fragment("gen_random_uuid()")
      add :provider_id, references(:provider, type: :bigint), null: false
      add :channel_name, :string, size: 30, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:channel, [:provider_id, :channel_name], name: :unique_channel)
    create index(:channel, [:ext_id])

    create table(:conversation, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :ext_id, :uuid, null: false, default: fragment("gen_random_uuid()")
      add :party_a_id, references(:party, type: :bigint), null: false
      add :party_b_id, references(:party, type: :bigint), null: false

      timestamps(type: :utc_datetime_usec)
    end

    create constraint(:conversation, :unique_party_pair,
             check: "party_a_id < party_b_id",
             comment: "Ensures ordered party pairs for conversation uniqueness"
           )

    create unique_index(:conversation, [:party_a_id, :party_b_id])
    create index(:conversation, [:ext_id])


    create table(:message, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :ext_id, :uuid, null: false, default: fragment("gen_random_uuid()")
      add :conversation_id, references(:conversation, type: :bigint), null: false
      add :channel_id, references(:channel, type: :bigint), null: false
      add :sender_id, references(:party, type: :bigint), null: false
      add :recipient_id, references(:party, type: :bigint), null: false
      add :body, :text
      add :sent_at, :utc_datetime_usec, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:message, [:ext_id])
    create index(:message, [:sent_at])

    create table(:attachment, primary_key: false) do
      add :id, :bigserial, primary_key: true
      add :ext_id, :uuid, null: false, default: fragment("gen_random_uuid()")
      add :message_id, references(:message, type: :bigint), null: false
      add :url, :text, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create index(:attachment, [:ext_id])
    create index(:attachment, [:message_id])
  end
end
