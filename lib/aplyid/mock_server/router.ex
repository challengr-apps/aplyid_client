defmodule Aplyid.MockServer.Router do
  @moduledoc """
  Plug router for the mock APLYiD server.

  Routes requests to appropriate handlers for:
  - Verification API endpoints (send_text, resend_text)
  - Verification flow UI (consent, capture, details, face)
  - Simulation endpoints (for testing)
  """

  use Plug.Router

  alias Aplyid.MockServer.Handlers.Verifications
  alias Aplyid.MockServer.Handlers.Simulation
  alias Aplyid.MockServer.Handlers.Verification
  alias Aplyid.MockServer.Responses

  plug(Plug.Logger, log: :debug)
  plug(:match)

  plug(Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["application/json", "application/x-www-form-urlencoded"],
    json_decoder: Jason
  )

  plug(:dispatch)

  # Verification endpoints
  post "/api/v2/send_text" do
    Verifications.send_text(conn)
  end

  put "/api/v2/resend_text/:transaction_id" do
    Verifications.resend_text(conn, transaction_id)
  end

  # Simulation endpoints (for testing/development)
  post "/mock/simulate/complete/:id" do
    Simulation.complete(conn, id)
  end

  # Verification flow UI endpoints
  get "/l/:id" do
    Verification.start(conn, id)
  end

  get "/l/:id/consent" do
    Verification.consent(conn, id)
  end

  post "/l/:id/consent" do
    Verification.submit_consent(conn, id)
  end

  get "/l/:id/capture" do
    Verification.capture(conn, id)
  end

  post "/l/:id/capture" do
    Verification.submit_capture(conn, id)
  end

  get "/l/:id/reviewing" do
    Verification.reviewing(conn, id)
  end

  get "/l/:id/details" do
    Verification.details(conn, id)
  end

  post "/l/:id/details" do
    Verification.submit_details(conn, id)
  end

  get "/l/:id/face" do
    Verification.face(conn, id)
  end

  post "/l/:id/face" do
    Verification.submit_face(conn, id)
  end

  get "/l/:id/complete" do
    Verification.complete(conn, id)
  end

  # Health check endpoint
  get "/health" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{status: "ok", server: "aplyid_mock"}))
  end

  # Catch-all for unmatched routes
  match _ do
    Responses.error(conn, 404, "not_found", "Endpoint not found")
  end
end
