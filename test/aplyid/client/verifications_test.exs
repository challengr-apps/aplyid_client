defmodule Aplyid.Client.VerificationsTest do
  use ExUnit.Case, async: true

  alias Aplyid.Client
  alias Aplyid.Client.Verifications

  defp build_client(plug) do
    Client.new(
      environment: :uat,
      api_key: "test_key",
      api_secret: "test_secret",
      base_url: "http://localhost",
      req_options: [plug: plug, retry: false]
    )
  end

  describe "create/2" do
    test "sends POST to /api/v2/send_text with params as JSON body" do
      response_body = %{
        "transaction_id" => "eUmE4voe-L_BRzjG"
      }

      plug = fn conn ->
        assert conn.method == "POST"
        assert conn.request_path == "/api/v2/send_text"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["reference"] == "my-ref-123"
        assert decoded["contact_phone"] == "61400000000"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)

      params = %{
        "reference" => "my-ref-123",
        "contact_phone" => "61400000000"
      }

      assert {:ok, ^response_body} = Verifications.create(client, params)
    end

    test "returns start_process_url when no phone is provided" do
      response_body = %{
        "transaction_id" => "c2jYDUbgZsYcr9Dx",
        "start_process_url" => "https://integration.aplyid.com/l/c2jYDUbgZsYcr9Dx"
      }

      plug = fn conn ->
        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        refute Map.has_key?(decoded, "contact_phone")

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               Verifications.create(client, %{"reference" => "my-ref-456"})
    end

    test "sets aply-api-key and aply-secret headers" do
      plug = fn conn ->
        [api_key] = Plug.Conn.get_req_header(conn, "aply-api-key")
        [api_secret] = Plug.Conn.get_req_header(conn, "aply-secret")
        assert api_key == "test_key"
        assert api_secret == "test_secret"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(%{"transaction_id" => "abc"}))
      end

      client = build_client(plug)
      assert {:ok, _} = Verifications.create(client, %{"reference" => "test"})
    end

    test "returns validation error for invalid params" do
      error_body = %{"message" => "Validation failed", "field" => "reference"}

      plug = fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(422, Jason.encode!(error_body))
      end

      client = build_client(plug)
      assert {:error, {:validation_error, ^error_body}} = Verifications.create(client, %{})
    end

    test "returns unauthorized for invalid API credentials" do
      plug = fn conn -> Plug.Conn.send_resp(conn, 401, "") end

      client = build_client(plug)
      assert {:error, :unauthorized} = Verifications.create(client, %{})
    end
  end

  describe "resend_sms/2" do
    test "sends PUT to /api/v2/resend_text/:transaction_id with empty body" do
      response_body = %{"transaction_id" => "new-txn-456"}

      plug = fn conn ->
        assert conn.method == "PUT"
        assert conn.request_path == "/api/v2/resend_text/txn-abc-123"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded == %{}

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)
      assert {:ok, ^response_body} = Verifications.resend_sms(client, "txn-abc-123")
    end
  end

  describe "resend_sms/3" do
    test "sends PUT to /api/v2/resend_text/:transaction_id with contact_phone" do
      response_body = %{"transaction_id" => "new-txn-789"}

      plug = fn conn ->
        assert conn.method == "PUT"
        assert conn.request_path == "/api/v2/resend_text/txn-abc-123"

        {:ok, body, conn} = Plug.Conn.read_body(conn)
        decoded = Jason.decode!(body)
        assert decoded["contact_phone"] == "61400111222"

        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.send_resp(200, Jason.encode!(response_body))
      end

      client = build_client(plug)

      assert {:ok, ^response_body} =
               Verifications.resend_sms(client, "txn-abc-123", %{
                 "contact_phone" => "61400111222"
               })
    end
  end
end
