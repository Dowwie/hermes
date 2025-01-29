defmodule Hermes.Repo do
  use Ecto.Repo,
    otp_app: :hermes,
    adapter: Ecto.Adapters.Postgres
end
