defmodule Aplyid.ClientTest do
  use ExUnit.Case, async: true

  alias Aplyid.Client

  describe "new/1" do
    test "creates client from environment config" do
      client = Client.new(environment: :uat)

      assert %Client{} = client
      assert client.environment == :uat
      assert client.base_url == "http://localhost"
      assert client.api_key == "test_api_key"
      assert client.api_secret == "test_api_secret"
      assert client.req_options == []
    end

    test "allows overriding base_url" do
      client = Client.new(environment: :uat, base_url: "https://custom.example.com")

      assert client.base_url == "https://custom.example.com"
    end

    test "allows overriding api_key" do
      client = Client.new(environment: :uat, api_key: "override_key")

      assert client.api_key == "override_key"
    end

    test "allows overriding api_secret" do
      client = Client.new(environment: :uat, api_secret: "override_secret")

      assert client.api_secret == "override_secret"
    end

    test "passes through req_options" do
      client = Client.new(environment: :uat, req_options: [receive_timeout: 30_000])

      assert client.req_options == [receive_timeout: 30_000]
    end

    test "raises when environment is missing" do
      assert_raise RuntimeError, ~r/environment is required/, fn ->
        Client.new([])
      end
    end

    test "raises when environment is not configured" do
      assert_raise RuntimeError, ~r/base_url not configured/, fn ->
        Client.new(environment: :nonexistent)
      end
    end
  end

  describe "uat/1" do
    test "creates client for UAT environment" do
      client = Client.uat()

      assert client.environment == :uat
      assert client.base_url == "http://localhost"
    end
  end
end
