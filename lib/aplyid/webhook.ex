defmodule Aplyid.Webhook do
  @moduledoc """
  Webhook support for receiving APLYiD verification notifications.

  APLYiD sends webhook notifications when verification statuses change.
  Use `Aplyid.Webhook.Plug` to receive these notifications and
  `Aplyid.Webhook.Handler` to process them.

  ## Event Types

    * `"created"` — Verification was created and SMS sent
    * `"completed"` — Verification was completed with results
    * `"updated"` — Verification was updated via the web application
    * `"archived"` — Verification reached end of lifecycle
    * `"error"` — Verification encountered an unexpected error
    * `"pending"` — Government data sources unavailable, retrying
    * `"test"` — Test webhook from the APLYiD dashboard

  ## Setup

      # In your Phoenix router
      forward "/webhooks/aplyid/uat", Aplyid.Webhook.Plug,
        environment: :uat,
        handler: MyApp.AplyidWebhookHandler

      forward "/webhooks/aplyid/prod", Aplyid.Webhook.Plug,
        environment: :production,
        handler: MyApp.AplyidWebhookHandler

  ## Handling Events

      defmodule MyApp.AplyidWebhookHandler do
        @behaviour Aplyid.Webhook.Handler

        @impl true
        def handle_event("completed", payload, _context) do
          transaction_id = payload["transaction_id"]
          verification = payload["verification"]
          # Process completed verification
          :ok
        end

        def handle_event(_event, _payload, _context), do: :ok
      end
  """
end
