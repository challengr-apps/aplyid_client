defmodule Aplyid.MockServer.Handlers.Verification do
  @moduledoc """
  Handles the user-facing verification flow screens for the mock server.

  This simulates the APLYiD verification experience with 6 screens:
  1. Privacy Consent
  2. Capture Photo ID
  3. Reviewing ID Data (brief loading)
  4. Check ID Details
  5. Face Verification
  6. Verification Complete
  """

  import Plug.Conn
  alias Aplyid.MockServer.State
  alias Aplyid.MockServer.Views

  @doc """
  GET /l/:id - Start verification flow (redirects to step 1)
  """
  def start(conn, id) do
    case State.get_transaction(id) do
      {:ok, transaction} ->
        case transaction.status do
          :created ->
            redirect(conn, "/l/#{id}/consent")

          :completed ->
            render_html(conn, Views.already_completed(transaction, path_prefix(conn)))

          _ ->
            render_html(conn, Views.error("This transaction is no longer available."))
        end

      :not_found ->
        render_html(conn, Views.error("Transaction not found."))
    end
  end

  @doc """
  GET /l/:id/consent - Privacy consent screen
  """
  def consent(conn, id) do
    case State.get_transaction(id) do
      {:ok, transaction} ->
        render_html(conn, Views.consent(transaction, path_prefix(conn)))

      :not_found ->
        render_html(conn, Views.error("Transaction not found."))
    end
  end

  @doc """
  POST /l/:id/consent - Submit consent, go to capture
  """
  def submit_consent(conn, id) do
    case State.get_transaction(id) do
      {:ok, _transaction} ->
        redirect(conn, "/l/#{id}/capture")

      :not_found ->
        render_html(conn, Views.error("Transaction not found."))
    end
  end

  @doc """
  GET /l/:id/capture - Capture photo ID screen
  """
  def capture(conn, id) do
    case State.get_transaction(id) do
      {:ok, transaction} ->
        render_html(conn, Views.capture(transaction, path_prefix(conn)))

      :not_found ->
        render_html(conn, Views.error("Transaction not found."))
    end
  end

  @doc """
  POST /l/:id/capture - Submit capture, go to reviewing
  """
  def submit_capture(conn, id) do
    case State.get_transaction(id) do
      {:ok, _transaction} ->
        redirect(conn, "/l/#{id}/reviewing")

      :not_found ->
        render_html(conn, Views.error("Transaction not found."))
    end
  end

  @doc """
  GET /l/:id/reviewing - Reviewing ID data (loading screen)
  """
  def reviewing(conn, id) do
    case State.get_transaction(id) do
      {:ok, transaction} ->
        render_html(conn, Views.reviewing(transaction, path_prefix(conn)))

      :not_found ->
        render_html(conn, Views.error("Transaction not found."))
    end
  end

  @doc """
  GET /l/:id/details - Check ID details screen
  """
  def details(conn, id) do
    case State.get_transaction(id) do
      {:ok, transaction} ->
        render_html(conn, Views.details(transaction, path_prefix(conn)))

      :not_found ->
        render_html(conn, Views.error("Transaction not found."))
    end
  end

  @doc """
  POST /l/:id/details - Submit details, go to face verification
  """
  def submit_details(conn, id) do
    case State.get_transaction(id) do
      {:ok, _transaction} ->
        redirect(conn, "/l/#{id}/face")

      :not_found ->
        render_html(conn, Views.error("Transaction not found."))
    end
  end

  @doc """
  GET /l/:id/face - Face verification screen
  """
  def face(conn, id) do
    case State.get_transaction(id) do
      {:ok, transaction} ->
        render_html(conn, Views.face(transaction, path_prefix(conn)))

      :not_found ->
        render_html(conn, Views.error("Transaction not found."))
    end
  end

  @doc """
  POST /l/:id/face - Submit face, complete verification
  """
  def submit_face(conn, id) do
    case State.get_transaction(id) do
      {:ok, _transaction} ->
        State.complete_transaction(id)
        redirect(conn, "/l/#{id}/complete")

      :not_found ->
        render_html(conn, Views.error("Transaction not found."))
    end
  end

  @doc """
  GET /l/:id/complete - Verification complete screen
  """
  def complete(conn, id) do
    case State.get_transaction(id) do
      {:ok, transaction} ->
        render_html(conn, Views.complete(transaction, path_prefix(conn)))

      :not_found ->
        render_html(conn, Views.error("Transaction not found."))
    end
  end

  # Helper functions

  defp render_html(conn, html) do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  defp redirect(conn, path) do
    prefix = path_prefix(conn)
    location = "#{prefix}#{path}"

    conn
    |> put_resp_header("location", location)
    |> send_resp(302, "")
  end

  # Extract path prefix from conn.script_name for embedded mode support.
  # When the router is mounted at e.g. /aplyid-mock via Phoenix's `forward`,
  # script_name = ["aplyid-mock"] and we return "/aplyid-mock".
  # When not mounted (standalone), returns "".
  defp path_prefix(conn) do
    case conn.script_name do
      [] -> ""
      parts -> "/" <> Enum.join(parts, "/")
    end
  end
end
