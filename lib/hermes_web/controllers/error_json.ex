# lib/hermes_web/controllers/error_json.ex
defmodule HermesWeb.ErrorJSON do
  @moduledoc """
  Renders errors as structured JSON without requiring template files.
  """

  # Generic error for 4xx/5xx status codes
  def render("404.json", _assigns) do
    %{
      error: %{
        code: "not_found",
        detail: "Resource not found"
      }
    }
  end

  # Handle Ecto changeset validation errors
  def render("422.json", %{reason: %Ecto.Changeset{} = changeset}) do
    %{
      error: %{
        code: "validation_failed",
        details: parse_changeset_errors(changeset)
      }
    }
  end

  # Catch-all for other 400 errors (like invalid JSON)
  def render("400.json", _assigns) do
    %{
      error: %{
        code: "invalid_request",
        detail: "Malformed request body"
      }
    }
  end

  # Fallback for all other errors
  def render(template, _assigns) do
    %{
      error: %{
        code: Phoenix.Controller.status_message_from_template(template),
        detail: "Unexpected error occurred"
      }
    }
  end

  defp parse_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
