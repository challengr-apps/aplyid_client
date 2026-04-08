# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.1.1] - 2026-04-08

### Added

- Logger calls in `Aplyid.Client.Request` (debug for requests, warning/error for failures)
- Logger warnings for auth failures in `Aplyid.Webhook.Plug`
- Debug logging in mock server router for incoming requests
- `config/prod.exs` for production builds
- GitHub Actions workflow running tests, format check, and compilation with warnings-as-errors on push/PR to main

### Changed

- Webhook `Req.post` calls now use a 15s `receive_timeout`
- Improved moduledocs for `Aplyid.MockServer.Responses` and the verifications handler

### Fixed

- Prevent crashes from `String.to_existing_atom/1` in mock server Postgres storage and `Schema.Transaction`
- Handle `{:error, _}` from `State.create_transaction` in mock server handlers
- Handle `Task.Supervisor.start_child` errors in async webhook delivery
- HTML-escape user-provided data in mock server views via `Plug.HTML.html_escape/1` (XSS)

## [0.1.0] - 2026-02-26

### Added

- Initial release of the Aplyid Elixir client library
- API client with multi-environment configuration support
- Verification endpoints: create and resend SMS
- Error handling with typed error structs
- Webhook handler behaviour and Plug integration
- Mock server with PostgreSQL persistence for development and testing
- Mock verification UI flow with 6-step process
- Programmatic transaction completion for automated testing
