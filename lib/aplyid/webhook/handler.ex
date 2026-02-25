defmodule Aplyid.Webhook.Handler do
  @moduledoc """
  Behaviour for handling APLYiD webhook events.

  Implement `handle_event/3` to process incoming webhook notifications.
  The event type is extracted from the `"event"` field in the JSON payload.

  Your handler is responsible for verifying the `Authorization` header if
  your webhook endpoint is configured with authentication. Return
  `{:error, :unauthorized}` to reject the request with a 401 response.

  ## Example

      defmodule MyApp.AplyidWebhookHandler do
        @behaviour Aplyid.Webhook.Handler

        @impl true
        def handle_event("completed", payload, context) do
          with :ok <- verify_authorization(context) do
            transaction_id = payload["transaction_id"]
            # Process completed verification
            :ok
          end
        end

        def handle_event(_type, _payload, _context) do
          # Gracefully ignore unknown event types
          :ok
        end

        defp verify_authorization(%{authorization: auth}) do
          expected = Application.get_env(:my_app, :aplyid_webhook_secret)

          if Plug.Crypto.secure_compare(auth || "", expected || "") do
            :ok
          else
            {:error, :unauthorized}
          end
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
end
