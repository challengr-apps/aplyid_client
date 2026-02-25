defmodule Aplyid.Webhook.PlugTest do
  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn

  defmodule TestHandler do
    @behaviour Aplyid.Webhook.Handler

    @impl true
    def handle_event(event_type, payload, context) do
      send(self(), {:webhook_received, event_type, payload, context})
      :ok
    end
  end

  defmodule UnauthorizedHandler do
    @behaviour Aplyid.Webhook.Handler

    @impl true
    def handle_event(_event_type, _payload, _context) do
      {:error, :unauthorized}
    end
  end

  defmodule ErrorHandler do
    @behaviour Aplyid.Webhook.Handler

    @impl true
    def handle_event(_event_type, _payload, _context) do
      {:error, :processing_failed}
    end
  end

  describe "event type extraction" do
    @opts Aplyid.Webhook.Plug.init(
            environment: :uat,
            handler: TestHandler
          )

    test "extracts 'created' event type" do
      payload = %{
        "event" => "created",
        "transaction_id" => "txn-123",
        "reference" => "my-ref"
      }

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Aplyid.Webhook.Plug.call(@opts)

      assert conn.status == 200
      assert_received {:webhook_received, "created", ^payload, %{environment: :uat}}
    end

    test "extracts 'completed' event type" do
      payload = %{
        "event" => "completed",
        "transaction_id" => "txn-123",
        "verification" => %{"status" => "approved"}
      }

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Aplyid.Webhook.Plug.call(@opts)

      assert conn.status == 200
      assert_received {:webhook_received, "completed", ^payload, %{environment: :uat}}
    end

    test "extracts 'updated' event type" do
      payload = %{"event" => "updated", "transaction_id" => "txn-123"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Aplyid.Webhook.Plug.call(@opts)

      assert conn.status == 200
      assert_received {:webhook_received, "updated", ^payload, %{environment: :uat}}
    end

    test "extracts 'archived' event type" do
      payload = %{"event" => "archived", "transaction_id" => "txn-123"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Aplyid.Webhook.Plug.call(@opts)

      assert conn.status == 200
      assert_received {:webhook_received, "archived", ^payload, %{environment: :uat}}
    end

    test "extracts 'error' event type" do
      payload = %{"event" => "error", "transaction_id" => "txn-123", "message" => "Failed"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Aplyid.Webhook.Plug.call(@opts)

      assert conn.status == 200
      assert_received {:webhook_received, "error", ^payload, %{environment: :uat}}
    end

    test "extracts 'pending' event type" do
      payload = %{"event" => "pending", "transaction_id" => "txn-123"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Aplyid.Webhook.Plug.call(@opts)

      assert conn.status == 200
      assert_received {:webhook_received, "pending", ^payload, %{environment: :uat}}
    end

    test "extracts 'test' event type" do
      payload = %{"event" => "test", "message" => "Hello from APLYiD! Web Hook Test"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Aplyid.Webhook.Plug.call(@opts)

      assert conn.status == 200
      assert_received {:webhook_received, "test", ^payload, %{environment: :uat}}
    end

    test "returns 'unknown' when event field is missing" do
      payload = %{"transaction_id" => "txn-123"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Aplyid.Webhook.Plug.call(@opts)

      assert conn.status == 200
      assert_received {:webhook_received, "unknown", ^payload, %{environment: :uat}}
    end
  end

  describe "successful dispatch" do
    @opts Aplyid.Webhook.Plug.init(
            environment: :uat,
            handler: TestHandler
          )

    test "passes authorization header to handler context" do
      payload = %{"event" => "completed", "transaction_id" => "txn-123"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", "Bearer secret-token")
        |> Aplyid.Webhook.Plug.call(@opts)

      assert conn.status == 200

      assert_received {:webhook_received, "completed", ^payload,
                       %{environment: :uat, authorization: "Bearer secret-token"}}
    end

    test "passes nil authorization when header is missing" do
      payload = %{"event" => "completed", "transaction_id" => "txn-123"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Aplyid.Webhook.Plug.call(@opts)

      assert conn.status == 200

      assert_received {:webhook_received, "completed", ^payload,
                       %{environment: :uat, authorization: nil}}
    end

    test "passes the configured environment to the handler" do
      prod_opts =
        Aplyid.Webhook.Plug.init(
          environment: :production,
          handler: TestHandler
        )

      payload = %{"event" => "completed", "transaction_id" => "txn-123"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Aplyid.Webhook.Plug.call(prod_opts)

      assert conn.status == 200

      assert_received {:webhook_received, "completed", ^payload,
                       %{environment: :production, authorization: nil}}
    end
  end

  describe "handler errors" do
    test "returns 401 when handler returns {:error, :unauthorized}" do
      opts =
        Aplyid.Webhook.Plug.init(
          environment: :uat,
          handler: UnauthorizedHandler
        )

      payload = %{"event" => "completed", "transaction_id" => "txn-123"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Aplyid.Webhook.Plug.call(opts)

      assert conn.status == 401
      assert Jason.decode!(conn.resp_body) == %{"error" => "unauthorized"}
    end

    test "returns 500 when handler returns {:error, reason}" do
      opts =
        Aplyid.Webhook.Plug.init(
          environment: :uat,
          handler: ErrorHandler
        )

      payload = %{"event" => "completed", "transaction_id" => "txn-123"}

      conn =
        conn(:post, "/", Jason.encode!(payload))
        |> put_req_header("content-type", "application/json")
        |> Aplyid.Webhook.Plug.call(opts)

      assert conn.status == 500
    end
  end

  describe "pre-parsed body (Phoenix)" do
    @opts Aplyid.Webhook.Plug.init(
            environment: :uat,
            handler: TestHandler
          )

    test "uses body_params when body has already been parsed by Plug.Parsers" do
      payload = %{
        "event" => "completed",
        "transaction_id" => "txn-123",
        "verification" => %{"status" => "approved"}
      }

      conn =
        conn(:post, "/", "")
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", "Bearer pre-parsed-token")
        |> Map.put(:body_params, payload)
        |> Aplyid.Webhook.Plug.call(@opts)

      assert conn.status == 200

      assert_received {:webhook_received, "completed", ^payload,
                       %{environment: :uat, authorization: "Bearer pre-parsed-token"}}
    end
  end

  describe "request validation" do
    @opts Aplyid.Webhook.Plug.init(
            environment: :uat,
            handler: TestHandler
          )

    test "returns 405 for non-POST methods" do
      conn = conn(:get, "/") |> Aplyid.Webhook.Plug.call(@opts)
      assert conn.status == 405
    end

    test "returns 400 for invalid JSON body" do
      conn =
        conn(:post, "/", "not valid json")
        |> put_req_header("content-type", "application/json")
        |> Aplyid.Webhook.Plug.call(@opts)

      assert conn.status == 400
    end
  end
end
