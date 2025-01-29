defmodule Hermes.ConversationTest do
  use ExUnit.Case, async: true
  alias Hermes.ConversationContext
  alias Hermes.Repo
  alias Hermes.Schema.{NormalizedMessage, Party, Channel, Message, Provider}

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Hermes.Repo)

    seeded_channels = Repo.all(Channel)
    provider = Repo.get_by(Provider, provider_name: "Provider One")

    {:ok, %{seeded_channels: seeded_channels, provider: provider}}
  end

  describe "save/1" do
    test "successfully saves message using seeded channel", %{seeded_channels: channels} do
      email_channel = Enum.find(channels, &(&1.channel_name == "email"))

      message = %NormalizedMessage{
        channel: :provider_email,
        from: "user@example.com",
        to: "support@example.com",
        body: "Test message",
        timestamp: DateTime.utc_now(),
        attachments: ["s3://attachment1"]
      }

      assert {:ok, _} = ConversationContext.save(message)
      assert Repo.one(Message).channel_id == email_channel.id
    end

    test "handles party conflicts using seeded channel", %{seeded_channels: channels} do
      message1 = %NormalizedMessage{
        channel: :provider_email,
        from: "user@example.com",
        to: "support@example.com",
        body: "First message",
        timestamp: DateTime.utc_now()
      }

      assert {:ok, _} = ConversationContext.save(message1)

      message2 = %NormalizedMessage{
        channel: :provider_email,
        from: "user@example.com",
        to: "support@example.com",
        body: "Second message",
        timestamp: DateTime.utc_now()
      }

      assert {:ok, _} = ConversationContext.save(message2)
      assert Repo.aggregate(Party, :count, :id) == 2
    end
  end

  describe "save_many/1" do
    @tag :capture_log
    test "processes batches using seeded channel" do
      messages =
        for i <- 1..10 do
          %{
            data: %NormalizedMessage{
              channel: :provider_email,
              from: "user#{i}@example.com",
              to: "support@example.com",
              body: "Message #{i}",
              timestamp: DateTime.utc_now()
            }
          }
        end

      assert :ok = ConversationContext.save_many(messages)
      assert Repo.aggregate(Message, :count, :id) == 10
    end
  end
end
