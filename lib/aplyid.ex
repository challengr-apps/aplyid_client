defmodule Aplyid do
  @moduledoc """
  Elixir client for the APLYiD identity verification API.

  ## Quick Start

      # Create a client for the UAT environment
      client = Aplyid.Client.new(environment: :uat)

      # Create a verification and send SMS
      {:ok, result} = Aplyid.Client.Verifications.create(client, %{
        "reference" => "my-ref-123",
        "contact_phone" => "61400000000"
      })

  ## Configuration

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
  """
end
