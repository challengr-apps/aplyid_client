defmodule Aplyid.Client.ErrorTest do
  use ExUnit.Case, async: true

  alias Aplyid.Client.Error

  describe "new/1" do
    test "creates unauthorized error" do
      error = Error.new(:unauthorized)

      assert error.type == :unauthorized
      assert error.status == 401
      assert error.message =~ "Unauthorized"
    end

    test "creates forbidden error" do
      error = Error.new(:forbidden)

      assert error.type == :forbidden
      assert error.status == 403
    end

    test "creates not_found error" do
      error = Error.new(:not_found)

      assert error.type == :not_found
      assert error.status == 404
    end

    test "creates validation_error with details" do
      details = %{"message" => "Invalid request", "field" => "reference"}
      error = Error.new({:validation_error, details})

      assert error.type == :validation_error
      assert error.status == 422
      assert error.details == details
    end

    test "creates client_error" do
      body = %{"message" => "Bad request"}
      error = Error.new({:client_error, 400, body})

      assert error.type == :client_error
      assert error.status == 400
      assert error.details == body
    end

    test "creates server_error" do
      body = %{"message" => "Internal error"}
      error = Error.new({:server_error, 500, body})

      assert error.type == :server_error
      assert error.status == 500
      assert error.details == body
    end

    test "creates request_failed error" do
      error = Error.new({:request_failed, :timeout})

      assert error.type == :request_failed
      assert error.message =~ "timeout"
    end
  end

  describe "helper functions" do
    test "message/1 returns the message" do
      error = Error.new(:unauthorized)
      assert Error.message(error) =~ "Unauthorized"
    end

    test "validation_error?/1 returns true for validation errors" do
      error = Error.new({:validation_error, %{}})
      assert Error.validation_error?(error)
    end

    test "validation_error?/1 returns false for other errors" do
      error = Error.new(:unauthorized)
      refute Error.validation_error?(error)
    end

    test "auth_error?/1 returns true for unauthorized errors" do
      error = Error.new(:unauthorized)
      assert Error.auth_error?(error)
    end

    test "auth_error?/1 returns false for other errors" do
      error = Error.new(:not_found)
      refute Error.auth_error?(error)
    end
  end
end
