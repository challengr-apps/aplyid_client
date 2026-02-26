# Aplyid

An Elixir client library for the [APLYiD Developer API](https://docs.aplyid.com/).

## Installation

Add `aplyid` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:aplyid, "~> 0.1.0"}
  ]
end
```

## Configuration

Configure environments in your `config/runtime.exs`:

```elixir
config :aplyid,
  environments: [
    uat: [
      base_url: "https://integration.aplyid.com",
      api_key: System.get_env("APLYID_UAT_API_KEY"),
      api_secret: System.get_env("APLYID_UAT_API_SECRET")
    ],
    production: [
      base_url: "https://app.aplyid.com",
      api_key: System.get_env("APLYID_API_KEY"),
      api_secret: System.get_env("APLYID_API_SECRET")
    ]
  ]
```

## Usage

### Creating a Client

```elixir
# Create a client for an environment
client = Aplyid.Client.new(environment: :uat)

# Shorthand for UAT
client = Aplyid.Client.uat()
```

### Identity Verification

```elixir
# Create a verification (sends SMS to user)
{:ok, result} = Aplyid.Client.Verifications.create(client, %{
  "reference" => "order-123",
  "email" => "user@example.com",
  "contact_phone" => "61400000000",
  "firstname" => "John",
  "lastname" => "Smith",
  "flow_type" => "SIMPLE2"
})

# result contains:
# %{"transaction_id" => "eUmE4voe-L_BRzjG"}

# When no contact_phone is provided, the response includes a URL for manual verification:
# %{"transaction_id" => "...", "start_process_url" => "https://..."}
```

```elixir
# Resend SMS notification
{:ok, result} = Aplyid.Client.Verifications.resend_sms(client, "transaction_id")

# Resend to a different phone number
{:ok, result} = Aplyid.Client.Verifications.resend_sms(client, "transaction_id", %{
  "contact_phone" => "61400111222"
})
```

### Webhook Notifications

Mount the webhook plug in your Phoenix router to receive verification events:

```elixir
# lib/my_app_web/router.ex
forward "/webhooks/aplyid/uat", Aplyid.Webhook.Plug,
  environment: :uat,
  handler: MyApp.AplyidWebhookHandler
```

Implement the handler with `use Aplyid.Webhook.Handler`:

```elixir
defmodule MyApp.AplyidWebhookHandler do
  use Aplyid.Webhook.Handler

  @impl true
  def handle_event("completed", payload, _context) do
    # Verification completed - payload contains results
    :ok
  end

  def handle_event(_event_type, _payload, _context), do: :ok
end
```

Event types: `"created"`, `"completed"`, `"updated"`, `"archived"`, `"error"`, `"pending"`, `"test"`.

#### Webhook Authentication

Authorization is verified automatically before `handle_event/3` is called. Configure `webhook_auth` in your environment config to match the token APLYiD sends:

```elixir
config :aplyid,
  environments: [
    uat: [
      base_url: "https://integration.aplyid.com",
      api_key: System.get_env("APLYID_UAT_API_KEY"),
      api_secret: System.get_env("APLYID_UAT_API_SECRET"),
      webhook_auth: System.get_env("APLYID_UAT_WEBHOOK_AUTH")
    ]
  ]
```

If `webhook_auth` is not configured, all requests are allowed. If configured, the plug compares the incoming `Authorization` header and returns 401 on mismatch.

To use custom auth logic, override `verify_authorization/1` in your handler:

```elixir
defmodule MyApp.AplyidWebhookHandler do
  use Aplyid.Webhook.Handler

  @impl true
  def verify_authorization(%{authorization: auth}) do
    if MyApp.Auth.valid_webhook_token?(auth), do: :ok, else: {:error, :unauthorized}
  end

  @impl true
  def handle_event("completed", payload, _context) do
    # ...
    :ok
  end
end
```

### Error Handling

All API calls return `{:ok, data}` or `{:error, error}`:

```elixir
case Aplyid.Client.Verifications.create(client, params) do
  {:ok, result} ->
    result["transaction_id"]

  {:error, %Aplyid.Client.Error{type: :unauthorized}} ->
    # Invalid API credentials

  {:error, %Aplyid.Client.Error{type: :validation_error} = error} ->
    # Validation failed - check error.details

  {:error, error} ->
    Aplyid.Client.Error.message(error)
end
```

## Mock Server

The library includes a built-in mock server for local development and testing. This allows you to:

- Develop without API credentials
- Run integration tests without hitting the real API
- Avoid per-transaction billing during development
- Walk through a mock verification UI flow

### Setting Up the Mock Server

#### 1. Add Optional Dependencies

The mock server requires Plug and optionally Ecto for persistence:

```elixir
def deps do
  [
    {:aplyid, "~> 0.1.0"},
    {:plug, "~> 1.14"},
    {:ecto_sql, "~> 3.10"},
    {:postgrex, "~> 0.17"}
  ]
end
```

#### 2. Configure the Mock Server

```elixir
# config/dev.exs or config/test.exs
config :aplyid, :mock_server,
  enabled: true,
  embedded: true,
  base_url: "http://localhost:4000/aplyid-mock",
  repo: MyApp.Repo
```

Configuration options:

| Option | Description | Default |
|--------|-------------|---------|
| `enabled` | Enable the mock server | `false` |
| `embedded` | Skip starting Bandit (use Phoenix instead) | `false` |
| `base_url` | Base URL for verification links | `"http://localhost:4000"` |
| `repo` | Ecto repo for PostgreSQL persistence | Required |
| `webhook_url` | URL to send webhook notifications to | `nil` |
| `webhook_auth` | Authorization header value for webhooks | `nil` |

#### 3. Create the Database Migration

```bash
mix ecto.gen.migration add_aplyid_mock_server
```

```elixir
# priv/repo/migrations/YYYYMMDDHHMMSS_add_aplyid_mock_server.exs
defmodule MyApp.Repo.Migrations.AddAplyidMockServer do
  use Ecto.Migration

  def up, do: Aplyid.MockServer.Migrations.up(version: 1)
  def down, do: Aplyid.MockServer.Migrations.down(version: 1)
end
```

```bash
mix ecto.migrate
```

#### 4. Mount in Your Phoenix Router

```elixir
# lib/my_app_web/router.ex
forward "/aplyid-mock", Aplyid.MockServer.Router
```

#### 5. Point Your Client at the Mock Server

```elixir
config :aplyid,
  environments: [
    uat: [
      base_url: "http://localhost:4000/aplyid-mock",
      api_key: "any_key",
      api_secret: "any_secret"
    ]
  ]
```

### Verification Flow UI

When you create a transaction without a `contact_phone`, the response includes a `start_process_url` pointing to the mock verification flow. Open this URL in a browser to walk through the screens:

1. **Privacy Consent** - User confirms they accept the privacy terms
2. **Capture Photo ID** - Simulates capturing an ID document
3. **Reviewing ID Data** - Brief loading screen
4. **Check ID Details** - Displays mock extracted data for confirmation
5. **Face Verification** - Simulates the liveness check
6. **Verification Complete** - Success screen

Completing this flow automatically marks the transaction as completed with realistic mock verification data and triggers any configured webhooks.

The verification URL is generated based on the `base_url` config. When mounted in Phoenix at `/aplyid-mock`, the URL will be `http://localhost:4000/aplyid-mock/l/:id`. The router uses `conn.script_name` to correctly handle path prefixes for all internal links and redirects.

### Programmatic Completion

For automated testing, skip the UI and complete transactions programmatically:

```elixir
# Via helper function
Aplyid.MockServer.complete_transaction(transaction_id)

# Via HTTP endpoint
POST /mock/simulate/complete/:transaction_id
```

### Mock Server API Endpoints

| Endpoint | Description |
|----------|-------------|
| `POST /api/v2/send_text` | Create verification transaction |
| `PUT /api/v2/resend_text/:id` | Resend SMS notification |
| `GET /l/:id` | Start verification flow (HTML) |
| `POST /mock/simulate/complete/:id` | Simulate completion |
| `GET /health` | Health check |

### Test Setup

```elixir
# config/test.exs
config :aplyid, :mock_server,
  enabled: true,
  embedded: true,
  repo: MyApp.Repo,
  base_url: "http://localhost:4000"

config :aplyid,
  environments: [
    uat: [
      base_url: "http://localhost:4000",
      api_key: "test_key",
      api_secret: "test_secret"
    ]
  ]
```

```elixir
# In your test setup
setup do
  Aplyid.MockServer.clear_all()
  :ok
end
```

## License

MIT
