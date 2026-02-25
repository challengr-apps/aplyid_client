defmodule Aplyid.MockServer.Responses do
  @moduledoc """
  Standardized response builders for the mock APLYiD API.
  """

  import Plug.Conn

  alias Aplyid.MockServer.Transaction

  @doc """
  Sends a JSON response with the given status and data.
  """
  @spec json(Plug.Conn.t(), integer(), map() | list()) :: Plug.Conn.t()
  def json(conn, status, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(data))
  end

  @doc """
  Sends a send_text success response.
  """
  @spec send_text_success(Plug.Conn.t(), Transaction.t()) :: Plug.Conn.t()
  def send_text_success(conn, transaction) do
    body = %{"transaction_id" => transaction.id}

    body =
      if transaction.contact_phone do
        body
      else
        Map.put(body, "start_process_url", transaction.start_process_url)
      end

    json(conn, 200, body)
  end

  @doc """
  Sends a resend_text success response.
  """
  @spec resend_text_success(Plug.Conn.t(), Transaction.t()) :: Plug.Conn.t()
  def resend_text_success(conn, transaction) do
    json(conn, 200, %{"transaction_id" => transaction.id})
  end

  @doc """
  Sends a simulation success response.
  """
  @spec simulation_success(Plug.Conn.t(), Transaction.t(), String.t()) :: Plug.Conn.t()
  def simulation_success(conn, transaction, action) do
    json(conn, 200, %{
      "transaction_id" => transaction.id,
      "status" => to_string(transaction.status),
      "action" => action,
      "message" => "Simulation completed successfully"
    })
  end

  @doc """
  Sends an error response.
  """
  @spec error(Plug.Conn.t(), integer(), String.t(), String.t() | nil) :: Plug.Conn.t()
  def error(conn, status, code, message \\ nil) do
    body = %{"error" => code}
    body = if message, do: Map.put(body, "message", message), else: body
    json(conn, status, body)
  end

  @doc """
  Sends a validation error response.
  """
  @spec validation_error(Plug.Conn.t(), map() | list()) :: Plug.Conn.t()
  def validation_error(conn, errors) do
    json(conn, 422, %{
      "error" => "validation_error",
      "details" => errors
    })
  end

  @doc """
  Builds the APLYiD webhook event payload for a transaction.
  """
  @spec build_webhook_payload(Transaction.t(), String.t()) :: map()
  def build_webhook_payload(%Transaction{} = txn, event) do
    %{
      "event" => event,
      "reference" => txn.reference,
      "external_id" => txn.external_id,
      "phone_number" => txn.contact_phone,
      "transaction_id" => txn.id,
      "verification" => txn.verification,
      "message" => txn.message
    }
  end
end
