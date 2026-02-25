defmodule Aplyid.MockServer.State do
  @moduledoc """
  State management for the mock server.

  Delegates to the PostgreSQL storage adapter.
  """

  alias Aplyid.MockServer.Storage.Postgres
  alias Aplyid.MockServer.Transaction
  alias Aplyid.MockServer.Webhook

  @doc """
  Creates a new transaction and stores it.
  """
  @spec create_transaction(map()) :: {:ok, Transaction.t()} | {:error, term()}
  def create_transaction(params) do
    Postgres.create_transaction(params)
  end

  @doc """
  Retrieves a transaction by ID.
  """
  @spec get_transaction(String.t()) :: {:ok, Transaction.t()} | :not_found
  def get_transaction(id) do
    Postgres.get_transaction(id)
  end

  @doc """
  Updates a transaction with the given changes.
  """
  @spec update_transaction(String.t(), map()) :: {:ok, Transaction.t()} | :not_found
  def update_transaction(id, updates) do
    Postgres.update_transaction(id, updates)
  end

  @doc """
  Marks a transaction as completed with mock verification data.

  After completion, triggers any configured webhook notifications.
  """
  @spec complete_transaction(String.t()) ::
          {:ok, Transaction.t()} | :not_found | {:error, :invalid_state}
  def complete_transaction(id) do
    case get_transaction(id) do
      {:ok, transaction} ->
        if Transaction.can_complete?(transaction) do
          now = DateTime.utc_now()

          updates = %{
            status: :completed,
            completed_at: now,
            verification: Transaction.generate_verification_result()
          }

          case update_transaction(id, updates) do
            {:ok, completed_transaction} ->
              Webhook.send_completion_webhook(completed_transaction)
              {:ok, completed_transaction}

            error ->
              error
          end
        else
          {:error, :invalid_state}
        end

      :not_found ->
        :not_found
    end
  end

  @doc """
  Lists all transactions.
  """
  @spec list_transactions() :: [Transaction.t()]
  def list_transactions do
    Postgres.list_transactions()
  end

  @doc """
  Clears all state (transactions).
  """
  @spec clear_all() :: :ok
  def clear_all do
    Postgres.clear_all()
  end
end
