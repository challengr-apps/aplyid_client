defmodule Aplyid.MockServer.Handlers.Simulation do
  @moduledoc """
  Handles simulation endpoints for the mock server.

  These endpoints allow simulating transaction lifecycle events
  for testing and development purposes.
  """

  alias Aplyid.MockServer.State
  alias Aplyid.MockServer.Responses

  @doc """
  Handles POST /mock/simulate/complete/:id - Simulate transaction completion.

  Marks a transaction as completed with mock verification data,
  simulating a user successfully completing the verification flow.
  """
  @spec complete(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  def complete(conn, id) do
    case State.complete_transaction(id) do
      {:ok, transaction} ->
        Responses.simulation_success(conn, transaction, "complete")

      :not_found ->
        Responses.error(conn, 404, "not_found", "Transaction not found")

      {:error, :invalid_state} ->
        case State.get_transaction(id) do
          {:ok, transaction} ->
            Responses.error(
              conn,
              422,
              "invalid_state",
              "Transaction in #{transaction.status} state cannot be completed"
            )

          :not_found ->
            Responses.error(conn, 404, "not_found", "Transaction not found")
        end
    end
  end
end
