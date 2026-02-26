defmodule Aplyid.Webhook.Handler do
  @moduledoc """
  Behaviour for handling APLYiD webhook events.

  Use `use Aplyid.Webhook.Handler` to get default implementations including
  authorization verification from environment config. Override callbacks as needed.

  ## Example

      defmodule MyApp.AplyidWebhookHandler do
        use Aplyid.Webhook.Handler

        @impl true
        def handle_event("completed", payload, _context) do
          transaction_id = payload["transaction_id"]
          # Process completed verification
          :ok
        end

        def handle_event(_type, _payload, _context), do: :ok
      end

  ## Custom Authorization

  The default `verify_authorization/1` checks the `Authorization` header against
  the `webhook_auth` value in the environment config. Override it for custom logic:

      defmodule MyApp.AplyidWebhookHandler do
        use Aplyid.Webhook.Handler

        @impl true
        def verify_authorization(%{authorization: auth}) do
          if MyApp.Auth.valid_webhook_token?(auth) do
            :ok
          else
            {:error, :unauthorized}
          end
        end

        @impl true
        def handle_event("completed", payload, _context) do
          # ...
          :ok
        end
      end

  ## Event Types

  The event type is taken from the `"event"` field in the webhook payload:

    * `"created"` — Verification was created and SMS sent
    * `"completed"` — Verification was completed with results
    * `"updated"` — Verification was updated via the web application
    * `"archived"` — Verification reached end of lifecycle
    * `"error"` — Verification encountered an unexpected error
    * `"pending"` — Government data sources unavailable, retrying
    * `"test"` — Test webhook from the APLYiD dashboard

  New event types may be added by APLYiD — always handle unknown types gracefully.

  ## Context

  The `context` map contains:

    * `:environment` — The environment atom (e.g. `:uat` or `:production`) from the plug config
    * `:authorization` — The raw `Authorization` header value from the request, or `nil` if absent
  """

  @doc """
  Called when a webhook event is received from APLYiD.

  Returns `:ok` to acknowledge the event, `{:error, :unauthorized}` to reject
  with a 401 response, or `{:error, reason}` if processing fails (500 response).
  """
  @callback handle_event(event_type :: String.t(), payload :: map(), context :: map()) ::
              :ok | {:error, :unauthorized} | {:error, term()}

  @doc """
  Called before `handle_event/3` to verify the request's authorization.

  The default implementation checks the `Authorization` header against the
  `webhook_auth` value in the environment config. If no `webhook_auth` is
  configured, all requests are allowed.

  Return `:ok` to allow the request or `{:error, :unauthorized}` to reject it.
  """
  @callback verify_authorization(context :: map()) ::
              :ok | {:error, :unauthorized}

  defmacro __using__(_opts) do
    quote do
      @behaviour Aplyid.Webhook.Handler

      @impl true
      def verify_authorization(context) do
        Aplyid.Webhook.Handler.default_verify_authorization(context)
      end

      @impl true
      def handle_event(_type, _payload, _context), do: :ok

      defoverridable verify_authorization: 1, handle_event: 3
    end
  end

  @doc false
  def default_verify_authorization(%{environment: env, authorization: auth}) do
    env_config =
      Application.get_env(:aplyid, :environments, [])
      |> Keyword.get(env, [])

    case Keyword.get(env_config, :webhook_auth) do
      nil ->
        :ok

      expected ->
        if Plug.Crypto.secure_compare(auth || "", expected) do
          :ok
        else
          {:error, :unauthorized}
        end
    end
  end
end
