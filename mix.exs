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
      name: "Aplyid"
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Aplyid.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:req, "~> 0.5.0"},
      {:jason, "~> 1.4"},
      {:plug, "~> 1.14", optional: true}
    ]
  end
end
