# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Aplyid is an Elixir API client library for the [APLYiD Developer API](https://docs.aplyid.com/). It provides identity verification via SMS-based flows, following standard OTP application conventions with a supervision tree.

## Sibling Projects

Very similar API client libraries exist in the parent directory and serve as reference implementations sharing the same patterns (Req, Plug, mock server, error handling conventions):

- **`../azupay`** — Client for the [AzuPay Payments API](https://developer.azupay.com.au/). Payments/disbursements via Australia's NPP. Uses API key auth (raw header). Has 13 resource modules — good reference for multi-resource clients and webhook integration.
- **`../idverse`** — Client for the IDVerse/IDKit identity verification API. Closest to Aplyid in purpose (KYC). Uses OAuth2 with a `TokenManager` GenServer and an immutable client pattern (each call returns `{{:ok, result}, updated_client}`). Mock server supports both ETS and PostgreSQL backends.

## Common Commands

- **Compile**: `mix compile`
- **Run tests**: `mix test`
- **Run a single test file**: `mix test test/aplyid_test.exs`
- **Run a single test by line**: `mix test test/aplyid_test.exs:5`
- **Format code**: `mix format`
- **Check formatting**: `mix format --check-formatted`
- **Fetch dependencies**: `mix deps.get`

## Architecture

- **Elixir 1.18+ / OTP 28** project built with Mix
- **OTP Application**: `Aplyid.Application` starts a supervisor with `:one_for_one` strategy
- **Module namespace**: All modules live under `Aplyid.*`
- **Testing**: ExUnit with doctests enabled
- **Authentication**: API key + secret via `aply-api-key` and `aply-secret` request headers
- **HTTP client**: Req (`~> 0.5.0`)
- **Return convention**: `{:ok, data} | {:error, term()}` — error atoms map HTTP status codes (401→`:unauthorized`, 403→`:forbidden`, 404→`:not_found`, 422→`{:validation_error, body}`)

## Key Modules

- `Aplyid.Client` — Main client struct; `new/1` and `uat/1` create clients from environment config
- `Aplyid.Client.Request` — Low-level HTTP layer (builds auth headers, maps errors)
- `Aplyid.Client.Verifications` — Verification endpoints: `create/2` (POST /api/v2/send_text), `resend_sms/2,3` (PUT /api/v2/resend_text/:id)
- `Aplyid.Client.Error` — Error struct with type atoms and helpers (`message/1`, `validation_error?/1`, `auth_error?/1`)
- `Aplyid.Webhook.Handler` — Behaviour for handling webhook events (`handle_event/3`)
- `Aplyid.Webhook.Plug` — Plug that parses incoming webhooks and delegates to a handler module

## Mock Server

A full mock server lives under `Aplyid.MockServer.*`, enabled via config:

- **Router**: Plug-based, serves `/api/v2/send_text`, `/api/v2/resend_text/:id`, `/mock/simulate/complete/:id`, `/health`
- **Persistence**: PostgreSQL via Ecto (`aplyid_mock_transactions` table); requires host app to provide an Ecto repo
- **Webhooks**: Async delivery via `Task.Supervisor` on transaction completion
- **Simulation**: `/mock/simulate/complete/:id` endpoint for triggering verification completion in tests

## Configuration

Multi-environment config in `config/config.exs` (credentials via env vars):

```elixir
config :aplyid,
  environments: [
    uat: [base_url: "...", api_key: "...", api_secret: "..."]
  ]
```

Mock server config (typically in `config/test.exs`):

```elixir
config :aplyid, :mock_server,
  enabled: true,
  embedded: true,
  repo: MyApp.Repo
```

## Dependencies

`req`, `jason`, `plug` (optional), `bandit` (optional), `ecto_sql` (optional), `postgrex` (test only)

## Current State

All core components are implemented: API client, verifications endpoint, error handling, webhook handler/plug, and mock server with PostgreSQL persistence. The mock server was added most recently and may need further test validation. A verification UI for the mock server (mentioned in PROMPTS.md) has not yet been built.
