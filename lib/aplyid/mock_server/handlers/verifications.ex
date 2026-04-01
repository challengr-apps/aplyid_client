defmodule Aplyid.MockServer.Handlers.Verifications do
  @moduledoc """
  Handles verification API endpoints for the mock server.

  Implements the APLYiD `/api/v2/send_text` and `/api/v2/resend_text/:id`
  endpoints with authentication checks via `aply-api-key` and `aply-secret`
  request headers.
  """

  alias Aplyid.MockServer.State
  alias Aplyid.MockServer.Responses

  @doc """
  Handles POST /api/v2/send_text - Create a new verification transaction.
  """
  @spec send_text(Plug.Conn.t()) :: Plug.Conn.t()
  def send_text(conn) do
    with_auth(conn, fn ->
      params = conn.body_params

      case validate_send_text_params(params) do
        :ok ->
          case State.create_transaction(params) do
            {:ok, transaction} ->
              Responses.send_text_success(conn, transaction)

            {:error, _reason} ->
              Responses.error(conn, 500, "internal_error", "Failed to create transaction")
          end

        {:error, errors} ->
          Responses.validation_error(conn, errors)
      end
    end)
  end

  @doc """
  Handles PUT /api/v2/resend_text/:transaction_id - Resend SMS for a transaction.
  """
  @spec resend_text(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def resend_text(conn, id) do
    with_auth(conn, fn ->
      case State.get_transaction(id) do
        {:ok, transaction} ->
          if transaction.status == :created do
            case State.update_transaction(id, %{status: :created}) do
              {:ok, updated} ->
                Responses.resend_text_success(conn, updated)

              _error ->
                Responses.error(conn, 500, "internal_error", "Failed to update transaction")
            end
          else
            Responses.error(
              conn,
              422,
              "invalid_state",
              "Transaction in #{transaction.status} state cannot be resent"
            )
          end

        :not_found ->
          Responses.error(conn, 404, "not_found", "Transaction not found")
      end
    end)
  end

  # Private helpers

  defp with_auth(conn, fun) do
    api_key = get_header(conn, "aply-api-key")
    api_secret = get_header(conn, "aply-secret")

    if api_key && api_secret do
      fun.()
    else
      Responses.error(conn, 401, "unauthorized", "Missing aply-api-key or aply-secret header")
    end
  end

  defp get_header(conn, header) do
    case Plug.Conn.get_req_header(conn, header) do
      [value] when value != "" -> value
      _ -> nil
    end
  end

  defp validate_send_text_params(params) do
    errors = %{}

    errors =
      if is_nil(params["reference"]) or params["reference"] == "",
        do: Map.put(errors, "reference", "is required"),
        else: errors

    if map_size(errors) == 0, do: :ok, else: {:error, errors}
  end
end
