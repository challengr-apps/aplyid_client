defmodule Aplyid.Client do
  @moduledoc """
  Main client module for the APLYiD identity verification API.

  This module provides a convenient interface for interacting with the APLYiD API
  using API key and secret authentication with the Req HTTP client library.

  ## Configuration

  Configure the client in your config files:

      config :aplyid,
        environments: [
          uat: [
            base_url: "https://integration.aplyid.com",
            api_key: "your_api_key",
            api_secret: "your_api_secret"
          ],
          production: [
            base_url: "https://app.aplyid.com",
            api_key: "your_api_key",
            api_secret: "your_api_secret"
          ]
        ]

  ## Usage

      client = Aplyid.Client.new(environment: :uat)
      {:ok, result} = Aplyid.Client.Verifications.create(client, %{...})
  """

  @type t :: %__MODULE__{
          environment: atom(),
          base_url: String.t(),
          api_key: String.t(),
          api_secret: String.t(),
          req_options: keyword()
        }

  defstruct [
    :environment,
    :base_url,
    :api_key,
    :api_secret,
    req_options: []
  ]

  @doc """
  Creates a new APLYiD API client.

  Reads API key, secret, and base URL from application config for the given environment.

  ## Options

    * `:environment` - The environment to use (`:uat` or `:production`) (required)
    * `:base_url` - Override the configured base URL (optional)
    * `:api_key` - Override the configured API key (optional)
    * `:api_secret` - Override the configured API secret (optional)
    * `:req_options` - Additional options to pass to Req (optional)

  ## Examples

      client = Aplyid.Client.new(environment: :uat)
      client = Aplyid.Client.new(environment: :production)
      client = Aplyid.Client.new(environment: :uat, api_key: "override_key")
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    environment =
      opts[:environment] || raise("environment is required (e.g., :uat or :production)")

    env_config = get_environment_config(environment)

    base_url =
      opts[:base_url] ||
        (env_config && Keyword.get(env_config, :base_url)) ||
        raise("base_url not configured for environment: #{inspect(environment)}")

    api_key =
      opts[:api_key] ||
        (env_config && Keyword.get(env_config, :api_key)) ||
        raise("api_key not configured for environment: #{inspect(environment)}")

    api_secret =
      opts[:api_secret] ||
        (env_config && Keyword.get(env_config, :api_secret)) ||
        raise("api_secret not configured for environment: #{inspect(environment)}")

    %__MODULE__{
      environment: environment,
      base_url: base_url,
      api_key: api_key,
      api_secret: api_secret,
      req_options: opts[:req_options] || []
    }
  end

  @doc """
  Creates a new client for the UAT environment.

  ## Examples

      client = Aplyid.Client.uat()
  """
  @spec uat(keyword()) :: t()
  def uat(opts \\ []) do
    opts
    |> Keyword.put(:environment, :uat)
    |> new()
  end

  defp get_environment_config(environment) do
    config = Application.get_env(:aplyid, :environments, [])
    Keyword.get(config, environment)
  end
end
