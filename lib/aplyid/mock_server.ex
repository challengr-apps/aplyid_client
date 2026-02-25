defmodule Aplyid.MockServer do
  @moduledoc """
  Mock APLYiD server for development and testing.

  This module provides a mock implementation of the APLYiD API that can
  run embedded in your application. It's useful for:

  - Local development without API credentials
  - Integration testing without hitting the real API
  - Avoiding per-transaction billing during development

  ## Configuration

  Add to your config files:

      # config/test.exs
      config :aplyid, :mock_server,
        enabled: true,
        repo: MyApp.Repo

      # Optional webhook delivery
      config :aplyid, :mock_server,
        enabled: true,
        repo: MyApp.Repo,
        webhook_url: "http://localhost:4000/webhooks/aplyid",
        webhook_auth: "Bearer my-secret-token"

  ## Migrations

  Generate a migration in your application:

      mix ecto.gen.migration add_aplyid_mock_server

  Then call the migration functions:

      defmodule MyApp.Repo.Migrations.AddAplyidMockServer do
        use Ecto.Migration

        def up, do: Aplyid.MockServer.Migrations.up(version: 1)
        def down, do: Aplyid.MockServer.Migrations.down(version: 1)
      end

  ## Embedded Mode (Phoenix Integration)

  Mount the mock server router in your Phoenix router:

      # In your Phoenix router
      forward "/", Aplyid.MockServer.Router

  Configure your APLYiD client to use your Phoenix URL:

      config :aplyid,
        environments: [
          uat: [
            base_url: "http://localhost:4000",
            api_key: "test_key",
            api_secret: "test_secret"
          ]
        ]

  ## Simulating Transaction Completion

  Use the simulation endpoint or helper function to mark transactions as completed:

      # Via HTTP endpoint
      POST /mock/simulate/complete/:transaction_id

      # Via helper function
      Aplyid.MockServer.complete_transaction(transaction_id)

  ## API Endpoints

  The mock server implements the following APLYiD API endpoints:

  - `POST /api/v2/send_text` - Create verification transaction
  - `PUT /api/v2/resend_text/:id` - Resend SMS notification
  - `POST /mock/simulate/complete/:id` - Simulate completion (mock only)
  - `GET /health` - Health check endpoint

  ## Verification UI

  The mock server includes a web-based verification flow at `/l/:id`. When a
  transaction is created without a `contact_phone`, the response includes a
  `start_process_url` that points to this flow.

  The verification URL is generated using the configured `base_url`:

      config :aplyid, :mock_server,
        enabled: true,
        embedded: true,
        base_url: "http://localhost:4000/aplyid-mock",
        repo: MyApp.Repo

  When mounted in a Phoenix app at `/aplyid-mock`, the verification URL will be
  `http://localhost:4000/aplyid-mock/l/:id`. The flow includes:

  1. Privacy Consent
  2. Photo ID Capture
  3. ID Data Review
  4. ID Details Confirmation
  5. Face Verification
  6. Completion

  Upon completing the flow, the transaction is marked as completed with mock
  verification data and any configured webhooks are triggered.
  """

  @doc """
  Returns the child spec for starting the mock server under a supervisor.
  """
  def child_spec(opts \\ []) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  @doc """
  Starts the mock server.

  Returns `:ignore` if the mock server is not enabled in config.
  """
  def start_link(opts \\ []) do
    enabled = Keyword.get(opts, :enabled, true)

    if enabled do
      Aplyid.MockServer.Supervisor.start_link(opts)
    else
      :ignore
    end
  end

  @doc """
  Returns the configured base URL for the mock server.

  Reads from the `:mock_server` config's `:base_url` key.
  Falls back to `"http://localhost"`.
  """
  @spec base_url() :: String.t()
  def base_url do
    config = Application.get_env(:aplyid, :mock_server, [])

    case Keyword.get(config, :base_url) do
      nil -> "http://localhost"
      url when is_binary(url) -> String.trim_trailing(url, "/")
    end
  end

  @doc """
  Clears all mock server state (transactions).

  Useful for resetting state between tests.
  """
  defdelegate clear_all(), to: Aplyid.MockServer.State

  @doc """
  Simulates completing a transaction.

  Marks the transaction as completed with mock verification data
  and triggers any configured webhook notifications.
  """
  defdelegate complete_transaction(id), to: Aplyid.MockServer.State
end
