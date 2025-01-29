defmodule HermesWeb do
  @moduledoc false

  def api_controller do
    quote do
      use Phoenix.Controller, namespace: HermesWeb.API, formats: [:json]

      import Plug.Conn
      unquote(verified_routes())
    end
  end

  def router do
    quote do
      # Import helpers for Kaffy
      use Phoenix.Router, helpers: true

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: HermesWeb.Endpoint,
        router: HermesWeb.Router
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
