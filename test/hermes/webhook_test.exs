defmodule HermesWeb.WebhookTest do
  use HermesWeb.ConnCase
  use Mimic

  @endpoint HermesWeb.Endpoint

  @valid_params %{
    "from" => "+14155552671",
    "to" => "+12125551234",
    "timestamp" => DateTime.utc_now() |> DateTime.to_iso8601()
  }

  setup do
    Mimic.stub(Hermes.Ingest.Producer, :push, fn _params -> :ok end)
    {:ok, conn: build_conn()}
  end

  test "valid SMS webhook", %{conn: conn} do
    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post("/api/webhooks/sms", Jason.encode!(@valid_params))

    assert response(conn, 202) == "{}"
  end

  test "invalid SMS webhook", %{conn: conn} do
    invalid_params = Map.drop(@valid_params, ["provider_id"])

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post("/api/webhooks/sms", Jason.encode!(invalid_params))

    assert response(conn, 202) == "{}"
  end

  @tag :capture_log
  test "webhook when queue is full", %{conn: conn} do
    Mimic.expect(Hermes.Ingest.Producer, :push, fn _params ->
      {:error, :queue_full}
    end)

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post("/api/webhooks/sms", Jason.encode!(@valid_params))

    assert response(conn, 503) == "{}"
    assert get_resp_header(conn, "retry-after") == ["1000"]
  end
end
