{:ok, _} = Application.ensure_all_started(:phoenix)
{:ok, _} = Application.ensure_all_started(:broadway)
{:ok, _} = Application.ensure_all_started(:hermes)

Mimic.copy(Hermes.Ingest.Pipeline)
Mimic.copy(Hermes.Ingest.Producer)

ExUnit.configure(capture_io: false)

Ecto.Adapters.SQL.Sandbox.mode(Hermes.Repo, :manual)

ExUnit.start()
