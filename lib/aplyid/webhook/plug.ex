defmodule Aplyid.Webhook.Plug do
  @moduledoc """
  Plug for receiving APLYiD webhook notifications.

  Parses the JSON payload, verifies authorization via the handler's
  `verify_authorization/1` callback, then delegates to `handle_event/3`.
  See `Aplyid.Webhook.Handler` for details.

  ## Options

    * `:handler` — Module implementing `Aplyid.Webhook.Handler` (required)
    * `:environment` — The environment atom, e.g. `:uat` or `:production` (required).
      Passed to the handler in the context map.

  ## Example

      # Mount once per environment at different paths
      forward "/webhooks/aplyid/uat", Aplyid.Webhook.Plug,
        environment: :uat,
        handler: MyApp.AplyidWebhookHandler

      forward "/webhooks/aplyid/prod", Aplyid.Webhook.Plug,
        environment: :production,
        handler: MyApp.AplyidWebhookHandler
  """

  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts) do
    %{
      handler: Keyword.fetch!(opts, :handler),
      environment: Keyword.fetch!(opts, :environment)
    }
  end

  @impl true
  def call(%{method: "POST"} = conn, config) do
    with {:ok, conn, payload} <- read_json_body(conn) do
      event_type = extract_event_type(payload)
      authorization = get_authorization_header(conn)

      context = %{
        environment: config.environment,
        authorization: authorization
      }

      with :ok <- config.handler.verify_authorization(context) do
        case config.handler.handle_event(event_type, payload, context) do
          :ok ->
            conn |> send_resp(200, "") |> halt()

          {:error, :unauthorized} ->
            unauthorized(conn)

          {:error, _reason} ->
            conn |> send_resp(500, "") |> halt()
        end
      else
        {:error, :unauthorized} ->
          unauthorized(conn)
      end
    else
      {:error, _reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{"error" => "bad_request"}))
        |> halt()
    end
  end

  def call(conn, _config) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(405, Jason.encode!(%{"error" => "method_not_allowed"}))
    |> halt()
  end

  defp unauthorized(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, Jason.encode!(%{"error" => "unauthorized"}))
    |> halt()
  end

  defp extract_event_type(payload) do
    Map.get(payload, "event", "unknown")
  end

  # When mounted behind Phoenix's Plug.Parsers, the body has already been
  # read and parsed into conn.body_params. Use that when available, and
  # fall back to reading the raw body for non-Phoenix usage.
  defp read_json_body(%{body_params: %Plug.Conn.Unfetched{}} = conn) do
    case Plug.Conn.read_body(conn) do
      {:ok, body, conn} ->
        case Jason.decode(body) do
          {:ok, payload} when is_map(payload) -> {:ok, conn, payload}
          _ -> {:error, :invalid_json}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp read_json_body(%{body_params: %{} = params} = conn) when params != %{} do
    {:ok, conn, params}
  end

  defp read_json_body(_conn), do: {:error, :invalid_json}

  defp get_authorization_header(conn) do
    case get_req_header(conn, "authorization") do
      [value] -> value
      _ -> nil
    end
  end
end
