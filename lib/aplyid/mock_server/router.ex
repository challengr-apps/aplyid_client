defmodule Aplyid.MockServer.Router do
  @moduledoc """
  Plug router for the mock APLYiD server.

  Routes requests to appropriate handlers for:
  - Verification API endpoints (send_text, resend_text)
  - Simulation endpoints (for testing)
  """

  use Plug.Router

  alias Aplyid.MockServer.Handlers.Verifications
  alias Aplyid.MockServer.Handlers.Simulation
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
