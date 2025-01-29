alias Hermes.Repo
alias Hermes.Schema.{Channel, Provider}

IO.puts("\n#{IO.ANSI.bright()}#{IO.ANSI.cyan()}=== Begin Seeding Database ===#{IO.ANSI.reset()}\n")

provider =
  %Provider{}
  |> Provider.changeset(%{
    provider_name: "Provider One",
    service_url: "https://provider-name.com"
  })
  |> Repo.insert!()

Enum.each(["sms", "mms", "email"], fn name ->
  %Channel{}
  |> Channel.changeset(%{
    provider_id: provider.id,
    channel_name: name
  })
  |> Repo.insert!()
end)

Process.sleep(100)

IO.puts("\n#{IO.ANSI.bright()}#{IO.ANSI.cyan()}=== Finished Seeding Database ===#{IO.ANSI.reset()}\n")
