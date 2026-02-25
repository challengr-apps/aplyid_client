if Code.ensure_loaded?(Ecto) do
  defmodule Aplyid.MockServer.Storage.Postgres do
    @moduledoc """
    PostgreSQL storage adapter for the mock server.

    Provides persistent storage using the parent application's Ecto Repo.

    ## Configuration

    Configure the mock server with your repo:

        config :aplyid, :mock_server,
          enabled: true,
          repo: MyApp.Repo

    ## Migrations

    Run the provided migrations before using PostgreSQL storage:

        defmodule MyApp.Repo.Migrations.AddAplyidMockServer do
          use Ecto.Migration

          def up, do: Aplyid.MockServer.Migrations.up(version: 1)
          def down, do: Aplyid.MockServer.Migrations.down(version: 1)
        end
    """

    @behaviour Aplyid.MockServer.Storage

    import Ecto.Query

    alias Aplyid.MockServer.Storage
    alias Aplyid.MockServer.Transaction
    alias Aplyid.MockServer.Schema.Transaction, as: TransactionSchema

    @impl Aplyid.MockServer.Storage
    def create_transaction(params) do
      repo = Storage.repo()
      transaction = Transaction.new(params)

      attrs = TransactionSchema.from_transaction(transaction)

      case %TransactionSchema{}
           |> TransactionSchema.create_changeset(attrs)
           |> repo.insert() do
        {:ok, schema} ->
          {:ok, TransactionSchema.to_transaction(schema)}

        {:error, changeset} ->
          {:error, changeset}
      end
    end

    @impl Aplyid.MockServer.Storage
    def get_transaction(id) do
      repo = Storage.repo()

      case repo.get(TransactionSchema, id) do
        nil -> :not_found
        schema -> {:ok, TransactionSchema.to_transaction(schema)}
      end
    end

    @impl Aplyid.MockServer.Storage
    def update_transaction(id, updates) do
      repo = Storage.repo()

      case repo.get(TransactionSchema, id) do
        nil ->
          :not_found

        schema ->
          attrs =
            updates
            |> Enum.map(fn
              {:status, v} when is_atom(v) -> {:status, to_string(v)}
              {k, v} when is_atom(k) -> {k, v}
              {k, v} -> {String.to_existing_atom(k), v}
            end)
            |> Map.new()

          case schema
               |> TransactionSchema.update_changeset(attrs)
               |> repo.update() do
            {:ok, updated_schema} ->
              {:ok, TransactionSchema.to_transaction(updated_schema)}

            {:error, changeset} ->
              {:error, changeset}
          end
      end
    end

    @impl Aplyid.MockServer.Storage
    def list_transactions do
      repo = Storage.repo()

      TransactionSchema
      |> order_by([t], desc: t.inserted_at)
      |> repo.all()
      |> Enum.map(&TransactionSchema.to_transaction/1)
    end

    @impl Aplyid.MockServer.Storage
    def clear_all do
      repo = Storage.repo()
      repo.delete_all(TransactionSchema)
      :ok
    end
  end
end
