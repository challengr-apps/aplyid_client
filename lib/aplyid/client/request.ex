defmodule Aplyid.Client.Request do
  @moduledoc """
  Handles HTTP requests to the APLYiD API using Req.

  This module provides low-level request functionality with automatic
  authentication and error handling.
  """

  alias Aplyid.Client

  @type http_method :: :get | :post | :put | :patch | :delete
  @type response :: {:ok, map() | list()} | {:error, term()}

  @doc """
  Makes an authenticated HTTP request to the API.
  """
  @spec request(Client.t(), http_method(), String.t(), keyword()) :: response()
  def request(%Client{} = client, method, path, opts \\ []) do
    url = build_url(client.base_url, path)
    headers = build_headers(client.api_key, client.api_secret)

    req_opts =
      opts
      |> Keyword.put(:url, url)
      |> Keyword.put(:method, method)
      |> Keyword.put(:headers, headers)
      |> Keyword.merge(client.req_options)

    case Req.request(req_opts) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %{status: 401}} ->
        {:error, :unauthorized}

      {:ok, %{status: 403}} ->
        {:error, :forbidden}

      {:ok, %{status: 404}} ->
        {:error, :not_found}

      {:ok, %{status: 422, body: body}} ->
        {:error, {:validation_error, body}}

      {:ok, %{status: status, body: body}} when status in 400..499 ->
        {:error, {:client_error, status, body}}

      {:ok, %{status: status, body: body}} when status in 500..599 ->
        {:error, {:server_error, status, body}}

      {:error, reason} ->
        {:error, {:request_failed, reason}}
    end
  end

  @doc "Makes a GET request."
  @spec get(Client.t(), String.t(), keyword()) :: response()
  def get(client, path, opts \\ []), do: request(client, :get, path, opts)

  @doc "Makes a POST request."
  @spec post(Client.t(), String.t(), keyword()) :: response()
  def post(client, path, opts \\ []), do: request(client, :post, path, opts)

  @doc "Makes a PUT request."
  @spec put(Client.t(), String.t(), keyword()) :: response()
  def put(client, path, opts \\ []), do: request(client, :put, path, opts)

  @doc "Makes a PATCH request."
  @spec patch(Client.t(), String.t(), keyword()) :: response()
  def patch(client, path, opts \\ []), do: request(client, :patch, path, opts)

  @doc "Makes a DELETE request."
  @spec delete(Client.t(), String.t(), keyword()) :: response()
  def delete(client, path, opts \\ []), do: request(client, :delete, path, opts)

  defp build_url(base_url, path) do
    path = if String.starts_with?(path, "/"), do: path, else: "/#{path}"
    base_url <> path
  end

  defp build_headers(api_key, api_secret) do
    [
      {"aply-api-key", api_key},
      {"aply-secret", api_secret},
      {"accept", "application/json"},
      {"content-type", "application/json"}
    ]
  end
end
