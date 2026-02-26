defmodule Aplyid.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :aplyid,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Elixir client for the APLYiD identity verification API",
      package: package(),
      name: "Aplyid",
      source_url: "https://github.com/challengr-apps/aplyid_client",
      homepage_url: "https://hexdocs.pm/aplyid",
      docs: [
        main: "readme",
        extras: ["README.md", "LICENSE"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Aplyid.Application, []}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/challengr-apps/aplyid_client"},
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:req, "~> 0.5.0"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:bandit, "~> 1.0", optional: true},
      {:plug, "~> 1.14", optional: true},
      {:ecto_sql, "~> 3.10", optional: true},
      {:postgrex, "~> 0.17", optional: true}
    ]
  end
end
