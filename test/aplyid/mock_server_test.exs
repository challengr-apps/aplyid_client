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
      assert body["start_process_url"] =~ "http://localhost:4000/l/"
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

    test "returns start_process_url when communication_method is link" do
      conn =
        authed_conn(:post, "/api/v2/send_text", %{
          "reference" => "test-ref-123",
          "contact_phone" => "+61400000000",
          "communication_method" => "link"
        })
        |> call()

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["transaction_id"]
      assert body["start_process_url"] =~ "http://localhost:4000/l/"
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

  describe "verification flow" do
    setup do
      {:ok, transaction} = create_transaction()
      {:ok, transaction: transaction}
    end

    test "GET /l/:id redirects to consent for created transaction", %{transaction: txn} do
      conn =
        conn(:get, "/l/#{txn.id}")
        |> call()

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["/l/#{txn.id}/consent"]
    end

    test "GET /l/:id shows already completed for completed transaction", %{transaction: txn} do
      {:ok, _} = State.complete_transaction(txn.id)

      conn =
        conn(:get, "/l/#{txn.id}")
        |> call()

      assert conn.status == 200
      assert conn.resp_body =~ "Already Verified"
    end

    test "GET /l/:id shows error for unknown transaction" do
      conn =
        conn(:get, "/l/unknown-id")
        |> call()

      assert conn.status == 200
      assert conn.resp_body =~ "Transaction not found"
    end

    test "GET /l/:id/consent renders consent screen", %{transaction: txn} do
      conn =
        conn(:get, "/l/#{txn.id}/consent")
        |> call()

      assert conn.status == 200
      assert conn.resp_body =~ "Privacy Consent"
      assert conn.resp_body =~ "APLYiD"
    end

    test "POST /l/:id/consent redirects to capture", %{transaction: txn} do
      conn =
        conn(:post, "/l/#{txn.id}/consent", "consent=on")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> call()

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["/l/#{txn.id}/capture"]
    end

    test "GET /l/:id/capture renders capture screen", %{transaction: txn} do
      conn =
        conn(:get, "/l/#{txn.id}/capture")
        |> call()

      assert conn.status == 200
      assert conn.resp_body =~ "Capture your Photo ID"
    end

    test "POST /l/:id/capture redirects to reviewing", %{transaction: txn} do
      conn =
        conn(:post, "/l/#{txn.id}/capture")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> call()

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["/l/#{txn.id}/reviewing"]
    end

    test "GET /l/:id/reviewing renders loading screen", %{transaction: txn} do
      conn =
        conn(:get, "/l/#{txn.id}/reviewing")
        |> call()

      assert conn.status == 200
      assert conn.resp_body =~ "Reviewing your ID Data"
      assert conn.resp_body =~ "setTimeout"
    end

    test "GET /l/:id/details renders details screen", %{transaction: txn} do
      conn =
        conn(:get, "/l/#{txn.id}/details")
        |> call()

      assert conn.status == 200
      assert conn.resp_body =~ "Check your ID details"
      assert conn.resp_body =~ "JOHN"
      assert conn.resp_body =~ "SMITH"
    end

    test "POST /l/:id/details redirects to face", %{transaction: txn} do
      conn =
        conn(:post, "/l/#{txn.id}/details", "consent=on")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> call()

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["/l/#{txn.id}/face"]
    end

    test "GET /l/:id/face renders face verification screen", %{transaction: txn} do
      conn =
        conn(:get, "/l/#{txn.id}/face")
        |> call()

      assert conn.status == 200
      assert conn.resp_body =~ "Face Verification"
    end

    test "POST /l/:id/face completes transaction and redirects to complete", %{transaction: txn} do
      conn =
        conn(:post, "/l/#{txn.id}/face")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> call()

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["/l/#{txn.id}/complete"]

      # Verify transaction is now completed
      {:ok, completed} = State.get_transaction(txn.id)
      assert completed.status == :completed
      assert completed.verification["overall_result"] == "PASS"
    end

    test "GET /l/:id/complete renders complete screen", %{transaction: txn} do
      {:ok, _} = State.complete_transaction(txn.id)

      conn =
        conn(:get, "/l/#{txn.id}/complete")
        |> call()

      assert conn.status == 200
      assert conn.resp_body =~ "Verification complete"
    end

    test "full verification flow completes successfully", %{transaction: txn} do
      # Step 1: Start -> redirects to consent
      conn = conn(:get, "/l/#{txn.id}") |> call()
      assert conn.status == 302

      # Step 2: Consent screen
      conn = conn(:get, "/l/#{txn.id}/consent") |> call()
      assert conn.status == 200
      assert conn.resp_body =~ "Privacy Consent"

      # Step 3: Submit consent -> capture
      conn =
        conn(:post, "/l/#{txn.id}/consent", "consent=on")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> call()

      assert conn.status == 302

      # Step 4: Capture screen
      conn = conn(:get, "/l/#{txn.id}/capture") |> call()
      assert conn.status == 200

      # Step 5: Submit capture -> reviewing
      conn =
        conn(:post, "/l/#{txn.id}/capture")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> call()

      assert conn.status == 302

      # Step 6: Details screen
      conn = conn(:get, "/l/#{txn.id}/details") |> call()
      assert conn.status == 200
      assert conn.resp_body =~ "Check your ID details"

      # Step 7: Submit details -> face
      conn =
        conn(:post, "/l/#{txn.id}/details", "consent=on")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> call()

      assert conn.status == 302

      # Step 8: Face screen
      conn = conn(:get, "/l/#{txn.id}/face") |> call()
      assert conn.status == 200

      # Step 9: Submit face -> completes and redirects
      conn =
        conn(:post, "/l/#{txn.id}/face")
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> call()

      assert conn.status == 302

      # Step 10: Complete screen
      conn = conn(:get, "/l/#{txn.id}/complete") |> call()
      assert conn.status == 200
      assert conn.resp_body =~ "Verification complete"

      # Verify final state
      {:ok, completed} = State.get_transaction(txn.id)
      assert completed.status == :completed
      assert completed.verification != nil
    end

    test "verification screens use path prefix when mounted", %{transaction: txn} do
      conn =
        conn(:get, "/l/#{txn.id}/consent")
        |> Map.put(:script_name, ["aplyid-mock"])
        |> call()

      assert conn.status == 200
      assert conn.resp_body =~ "/aplyid-mock/l/#{txn.id}/consent"
    end

    test "redirects include path prefix when mounted", %{transaction: txn} do
      conn =
        conn(:get, "/l/#{txn.id}")
        |> Map.put(:script_name, ["aplyid-mock"])
        |> call()

      assert conn.status == 302
      assert get_resp_header(conn, "location") == ["/aplyid-mock/l/#{txn.id}/consent"]
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
