defmodule Aplyid.Client.RequestTest do
  use ExUnit.Case, async: true

  alias Aplyid.Client
  alias Aplyid.Client.Request

  defp build_client(plug) do
    Client.new(
      environment: :uat,
      api_key: "test_key",
      api_secret: "test_secret",
      base_url: "http://localhost",
      req_options: [plug: plug, retry: false]
    )
  end

  test "successful POST returns {:ok, body}" do
    plug = fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(201, Jason.encode!(%{"id" => "123"}))
    end

    client = build_client(plug)
    assert {:ok, %{"id" => "123"}} = Request.post(client, "/test", json: %{})
  end

  test "sets aply-api-key and aply-secret headers" do
    plug = fn conn ->
      [api_key] = Plug.Conn.get_req_header(conn, "aply-api-key")
      [api_secret] = Plug.Conn.get_req_header(conn, "aply-secret")
      body = Jason.encode!(%{"api_key" => api_key, "api_secret" => api_secret})

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(200, body)
    end

    client = build_client(plug)

    assert {:ok, %{"api_key" => "test_key", "api_secret" => "test_secret"}} =
             Request.get(client, "/test")
  end

  test "401 returns {:error, :unauthorized}" do
    plug = fn conn -> Plug.Conn.send_resp(conn, 401, "") end
    client = build_client(plug)
    assert {:error, :unauthorized} = Request.get(client, "/test")
  end

  test "403 returns {:error, :forbidden}" do
    plug = fn conn -> Plug.Conn.send_resp(conn, 403, "") end
    client = build_client(plug)
    assert {:error, :forbidden} = Request.get(client, "/test")
  end

  test "404 returns {:error, :not_found}" do
    plug = fn conn -> Plug.Conn.send_resp(conn, 404, "") end
    client = build_client(plug)
    assert {:error, :not_found} = Request.get(client, "/test")
  end

  test "422 returns {:error, {:validation_error, body}}" do
    body = %{"message" => "Validation failed", "details" => %{"field" => "reference"}}

    plug = fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(422, Jason.encode!(body))
    end

    client = build_client(plug)
    assert {:error, {:validation_error, ^body}} = Request.get(client, "/test")
  end

  test "500 returns {:error, {:server_error, 500, body}}" do
    plug = fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(500, Jason.encode!(%{"message" => "Internal error"}))
    end

    client = build_client(plug)
    assert {:error, {:server_error, 500, _body}} = Request.get(client, "/test")
  end

  test "builds URL with leading slash" do
    plug = fn conn ->
      body = Jason.encode!(%{"path" => conn.request_path})

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.send_resp(200, body)
    end

    client = build_client(plug)
    assert {:ok, %{"path" => "/test"}} = Request.get(client, "test")
  end
end
