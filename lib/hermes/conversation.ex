defmodule Hermes.ConversationContext do
  @moduledoc """
  Context module handling entity resolution and message persistence.
  """

  require Logger

  alias Hermes.Repo
  alias Ecto.Multi
  alias Hermes.Schema.{NormalizedMessage, Party, Channel, Conversation, Message, Attachment}

  @batch_size 100

  def save_many(messages) when is_list(messages) do
    messages
    |> Stream.chunk_every(@batch_size)
    |> Task.async_stream(fn batch ->
      Enum.each(batch, fn %{data: message} -> save(message) end)
    end)
    |> Stream.run()

    :ok
  end

  def save(%NormalizedMessage{} = message) do
    multi =
      Multi.new()
      |> Multi.run(:channel, fn repo, _changes ->
        resolve_channel(repo, message.channel)
      end)
      |> Multi.run(:sender_party, fn repo, _changes ->
        resolve_party(repo, message.from, message.channel)
      end)
      |> Multi.run(:recipient_party, fn repo, _changes ->
        resolve_party(repo, message.to, message.channel)
      end)
      |> Multi.run(:conversation, fn repo, %{sender_party: sender, recipient_party: recipient} ->
        resolve_conversation(repo, sender, recipient)
      end)
      |> Multi.run(:message, fn repo,
                                %{conversation: conv, channel: chan, sender_party: sender, recipient_party: recipient} ->
        save_message(repo, conv, chan, sender, recipient, message)
      end)
      |> Multi.run(:attachments, fn repo, %{message: msg} ->
        save_attachments(repo, msg, message.attachments)
      end)

    case Repo.transaction(multi) do
      {:ok, %{message: saved_message, attachments: attachment_count}} ->
        :telemetry.execute([:hermes, :messages, :saved, message.channel], %{count: 1}, %{})

        if attachment_count > 0 do
          :telemetry.execute([:hermes, :attachments, :saved], %{count: attachment_count}, %{})
        end

        {:ok, saved_message}

      {:error, failed_operation, reason, _changes} ->
        Logger.error("Failed to save message: #{inspect(reason)}")

        {:error, {failed_operation, reason}}
    end
  end

  defp resolve_channel(repo, channel_type) do
    channel_name = channel_name_for_type(channel_type)

    case repo.get_by(Channel, channel_name: channel_name) do
      nil -> {:error, "Channel #{channel_name} not found"}
      channel -> {:ok, channel}
    end
  end

  defp channel_name_for_type(:provider_sms), do: "sms"
  defp channel_name_for_type(:provider_mms), do: "mms"
  defp channel_name_for_type(:provider_email), do: "email"

  defp resolve_party(repo, identifier, channel_type) do
    # the identifier is either an email or a phone number
    case channel_type do
      :provider_email -> find_or_create_party(repo, %{email: identifier})
      _ -> find_or_create_party(repo, %{phone_e164: identifier})
    end
  end

  defp find_or_create_party(repo, %{email: email} = fields) when is_binary(email) do
    case repo.get_by(Party, email: email) do
      nil ->
        changeset = Party.changeset(%Party{}, fields)

        case repo.insert(changeset) do
          {:ok, party} ->
            {:ok, party}

          {:error, %Ecto.Changeset{errors: [email: {_, [constraint: :unique, constraint_name: _]}]}} ->
            {:ok, repo.get_by!(Party, email: email)}

          {:error, changeset} ->
            {:error, changeset}
        end

      existing_party ->
        {:ok, existing_party}
    end
  end

  defp find_or_create_party(repo, %{phone_e164: phone} = fields) when is_binary(phone) do
    case repo.get_by(Party, phone_e164: phone) do
      nil ->
        changeset = Party.changeset(%Party{}, fields)

        case repo.insert(changeset) do
          {:ok, party} ->
            {:ok, party}

          {:error, %Ecto.Changeset{errors: [phone_e164: {_, [constraint: :unique, constraint_name: _]}]}} ->
            # If we hit a unique constraint, fetch the existing record
            {:ok, repo.get_by!(Party, phone_e164: phone)}

          {:error, changeset} ->
            {:error, changeset}
        end

      existing_party ->
        {:ok, existing_party}
    end
  end

  defp resolve_conversation(repo, sender, recipient) do
    {party_a, party_b} = ordered_parties(sender, recipient)

    conversation_changeset =
      %Conversation{}
      |> Conversation.changeset(%{
        party_a_id: party_a.id,
        party_b_id: party_b.id
      })

    case repo.insert(
           conversation_changeset,
           conflict_target: [:party_a_id, :party_b_id],
           on_conflict: {:replace, [:updated_at]},
           returning: true
         ) do
      {:ok, conversation} ->
        {:ok, conversation}

      {:error, _changeset} ->
        # Fallback to get_by since we know the record should exist
        {:ok,
         repo.get_by!(Conversation,
           party_a_id: party_a.id,
           party_b_id: party_b.id
         )}
    end
  end

  defp ordered_parties(a, b) do
    if a.id < b.id, do: {a, b}, else: {b, a}
  end

  defp save_message(repo, conversation, channel, sender, recipient, normalized_msg) do
    %Message{}
    |> Message.changeset(%{
      body: normalized_msg.body,
      sent_at: normalized_msg.timestamp,
      conversation_id: conversation.id,
      channel_id: channel.id,
      sender_id: sender.id,
      recipient_id: recipient.id
    })
    |> repo.insert()
  end

  defp save_attachments(_repo, _message, nil), do: {:ok, 0}
  defp save_attachments(_repo, _message, []), do: {:ok, 0}

  defp save_attachments(repo, message, urls) when is_list(urls) do
    attachments =
      Enum.map(urls, fn url ->
        %Attachment{}
        |> Attachment.changeset(%{
          message_id: message.id,
          url: url
        })
        |> repo.insert!()
      end)

    {:ok, length(attachments)}
  end
end
