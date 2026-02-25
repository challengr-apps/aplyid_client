defmodule Aplyid.MockServerTest do
  use ExUnit.Case

  import Plug.Conn
  import Plug.Test

  alias Aplyid.MockServer.Router
  alias Aplyid.MockServer.State

  @auth_headers [{"aply-api-key", "test_key"}, {"aply-secret", "test_secret"}]

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Aplyid.TestRepo)
    State.clear_all()
    :ok
  end

  defp call(conn) do
    conn
    |> put_private(:plug_skip_csrf_protection, true)
    |> Router.call(Router.init([]))
  end

  defp json_conn(method, path, body \\ nil) do
    conn = conn(method, path, body && Jason.encode!(body))

    conn
    |> put_req_header("content-type", "application/json")
  end

  defp authed_conn(method, path, body \\ nil) do
    conn = json_conn(method, path, body)

    Enum.reduce(@auth_headers, conn, fn {key, value}, acc ->
      put_req_header(acc, key, value)
    end)
  end

  describe "POST /api/v2/send_text" do
    test "creates transaction with valid params" do
      conn =
        authed_conn(:post, "/api/v2/send_text", %{
          "reference" => "test-ref-123",
          "email" => "test@example.com",
          "contact_phone" => "+61400000000",
          "firstname" => "John",
          "lastname" => "Smith"
        })
        |> call()

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["transaction_id"]
    end

    test "returns start_process_url when no contact_phone" do
      conn =
        authed_conn(:post, "/api/v2/send_text", %{
          "reference" => "test-ref-123",
          "email" => "test@example.com"
        })
        |> call()

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["transaction_id"]
      assert body["start_process_url"]
    end

    test "omits start_process_url when contact_phone is provided" do
      conn =
        authed_conn(:post, "/api/v2/send_text", %{
          "reference" => "test-ref-123",
          "contact_phone" => "+61400000000"
        })
        |> call()

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["transaction_id"]
      refute body["start_process_url"]
    end

    test "returns validation error with missing reference" do
      conn =
        authed_conn(:post, "/api/v2/send_text", %{"email" => "test@example.com"})
        |> call()

      assert conn.status == 422
      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "validation_error"
      assert body["details"]["reference"]
    end

    test "returns 401 without auth headers" do
      conn =
        json_conn(:post, "/api/v2/send_text", %{"reference" => "test-ref"})
        |> call()

      assert conn.status == 401
      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "unauthorized"
    end

    test "returns 401 with only api key" do
      conn =
        json_conn(:post, "/api/v2/send_text", %{"reference" => "test-ref"})
        |> put_req_header("aply-api-key", "test_key")
        |> call()

      assert conn.status == 401
    end
  end

  describe "PUT /api/v2/resend_text/:transaction_id" do
    setup do
      {:ok, transaction} = create_transaction()
      {:ok, transaction: transaction}
    end

    test "resends for created transaction", %{transaction: txn} do
      conn =
        authed_conn(:put, "/api/v2/resend_text/#{txn.id}")
        |> call()

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["transaction_id"] == txn.id
    end

    test "returns 404 for unknown transaction" do
      conn =
        authed_conn(:put, "/api/v2/resend_text/unknown-id")
        |> call()

      assert conn.status == 404
    end

    test "returns 422 for completed transaction", %{transaction: txn} do
      {:ok, _} = State.complete_transaction(txn.id)

      conn =
        authed_conn(:put, "/api/v2/resend_text/#{txn.id}")
        |> call()

      assert conn.status == 422
      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "invalid_state"
    end

    test "returns 401 without auth headers", %{transaction: txn} do
      conn =
        json_conn(:put, "/api/v2/resend_text/#{txn.id}")
        |> call()

      assert conn.status == 401
    end
  end

  describe "POST /mock/simulate/complete/:id" do
    setup do
      {:ok, transaction} = create_transaction()
      {:ok, transaction: transaction}
    end

    test "completes a created transaction", %{transaction: txn} do
      conn =
        json_conn(:post, "/mock/simulate/complete/#{txn.id}")
        |> call()

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["status"] == "completed"
      assert body["action"] == "complete"
    end

    test "returns 404 for unknown transaction" do
      conn =
        json_conn(:post, "/mock/simulate/complete/unknown-id")
        |> call()

      assert conn.status == 404
    end

    test "returns 422 for already completed transaction", %{transaction: txn} do
      {:ok, _} = State.complete_transaction(txn.id)

      conn =
        json_conn(:post, "/mock/simulate/complete/#{txn.id}")
        |> call()

      assert conn.status == 422
      body = Jason.decode!(conn.resp_body)
      assert body["error"] == "invalid_state"
    end

    test "completed transaction has verification data", %{transaction: txn} do
      {:ok, completed} = State.complete_transaction(txn.id)
      assert completed.verification["overall_result"] == "PASS"
      assert completed.completed_at
    end
  end

  describe "GET /health" do
    test "returns ok status" do
      conn =
        conn(:get, "/health")
        |> call()

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["status"] == "ok"
      assert body["server"] == "aplyid_mock"
    end
  end

  describe "catch-all" do
    test "returns 404 for unknown routes" do
      conn =
        conn(:get, "/unknown/path")
        |> call()

      assert conn.status == 404
    end
  end

  describe "State.clear_all/0" do
    test "clears all transactions" do
      {:ok, _} = create_transaction()
      {:ok, _} = create_transaction()

      transactions = State.list_transactions()
      assert length(transactions) == 2

      State.clear_all()

      assert State.list_transactions() == []
    end
  end

  # Helper functions

  defp create_transaction(params \\ %{}) do
    default_params = %{
      "reference" => "test-ref-#{System.unique_integer([:positive])}",
      "email" => "test@example.com",
      "firstname" => "John",
      "lastname" => "Smith"
    }

    State.create_transaction(Map.merge(default_params, params))
  end
end
