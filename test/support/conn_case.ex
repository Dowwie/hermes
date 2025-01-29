defmodule HermesWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  controller tests.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.ConnTest
      import Plug.Conn
      import HermesWeb.ConnCase

      alias HermesWeb.Endpoint
      @endpoint HermesWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Hermes.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Hermes.Repo, {:shared, self()})
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
