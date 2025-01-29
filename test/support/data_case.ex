defmodule Hermes.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Hermes.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Hermes.DataCase
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Hermes.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Hermes.Repo, {:shared, self()})
    end

    :ok
  end
end
