defmodule HermesWeb.Plugs.CacheBodyReader do
  alias Plug.Conn

  @doc """
  Read the raw body and store it for later use in the connection.
  It ignores the updated connection returned by `Plug.Conn.read_body/2` to not break CSRF.
  """
  @spec read_body(Conn.t(), Plug.opts()) :: {:ok, String.t(), Conn.t()}
  def read_body(conn, opts) do
    {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
    conn = update_in(conn.assigns[:raw_body], &[body | &1 || []])
    {:ok, body, conn}
  end
end
