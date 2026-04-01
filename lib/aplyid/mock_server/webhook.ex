defmodule Aplyid.MockServer.Webhook do
  @moduledoc """
  Handles webhook notifications for transaction lifecycle events.

  When a transaction completes and a global webhook URL is configured,
  this module sends an HTTP POST request to the configured URL.

  ## Configuration

      config :aplyid, :mock_server,
        enabled: true,
        repo: MyApp.Repo,
        webhook_url: "http://localhost:4000/webhooks/aplyid",
        webhook_auth: "Bearer my-secret-token"
  """

  require Logger

  alias Aplyid.MockServer.Transaction
  alias Aplyid.MockServer.Responses

  @doc """
  Sends a completion webhook for a transaction asynchronously.
  """
  @spec send_completion_webhook(Transaction.t()) :: :ok
  def send_completion_webhook(%Transaction{} = transaction) do
    config = Application.get_env(:aplyid, :mock_server, [])
    webhook_url = Keyword.get(config, :webhook_url)

    if webhook_url do
      payload = Responses.build_webhook_payload(transaction, "completed")
      webhook_auth = Keyword.get(config, :webhook_auth)

      case Task.Supervisor.start_child(
             Aplyid.MockServer.TaskSupervisor,
             fn -> send_webhook(webhook_url, payload, webhook_auth) end
           ) do
        {:ok, _pid} ->
          :ok

        {:error, reason} ->
          Logger.error("Failed to start webhook delivery task: #{inspect(reason)}")
          :ok
      end
    end

    :ok
  end

  @doc """
  Sends a single webhook request synchronously.
  """
  @spec send_webhook(String.t(), map(), String.t() | nil) ::
          {:ok, integer()} | {:error, term()}
  def send_webhook(url, payload, auth \\ nil) do
    headers = [{"content-type", "application/json"}]
    headers = if auth, do: [{"authorization", auth} | headers], else: headers

    Logger.debug("Sending webhook to #{url}")

    case Req.post(url, json: payload, headers: headers, retry: false, receive_timeout: 15_000) do
      {:ok, %{status: status}} when status in 200..299 ->
        Logger.debug("Webhook to #{url} succeeded with status #{status}")
        {:ok, status}

      {:ok, %{status: status, body: body}} ->
        Logger.warning("Webhook to #{url} failed with status #{status}: #{inspect(body)}")
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        Logger.warning("Webhook to #{url} failed: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
