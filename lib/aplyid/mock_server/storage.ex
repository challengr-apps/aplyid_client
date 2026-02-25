defmodule Aplyid.MockServer.Storage do
  @moduledoc """
  Storage behaviour for mock server persistence.

  The mock server uses PostgreSQL for storage via the host application's
  Ecto Repo.

  ## Configuration

  Configure the mock server with your repo:

      config :aplyid, :mock_server,
        enabled: true,
        repo: MyApp.Repo
  """

  alias Aplyid.MockServer.Transaction

  @callback create_transaction(params :: map()) :: {:ok, Transaction.t()} | {:error, term()}
  @callback get_transaction(id :: String.t()) :: {:ok, Transaction.t()} | :not_found
  @callback update_transaction(id :: String.t(), updates :: map()) ::
              {:ok, Transaction.t()} | :not_found
  @callback list_transactions() :: [Transaction.t()]
  @callback clear_all() :: :ok

  @doc """
  Returns the configured Ecto repo, or nil if not configured.
  """
  @spec repo() :: module() | nil
  def repo do
    Application.get_env(:aplyid, :mock_server, [])[:repo]
  end
end
