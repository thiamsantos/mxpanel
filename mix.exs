defmodule Mxpanel.MixProject do
  use Mix.Project

  @name "Mxpanel"
  @version "0.1.0-dev"
  @description "Client for Mixpanel Ingestion API"
  @repo_url "https://github.com/thiamsantos/mxpanel"

  def project do
    [
      app: :mxpanel,
      version: @version,
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      name: @name,
      description: @description,
      deps: deps(),
      docs: docs(),
      package: package(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:nimble_options, "~> 0.3.5"},
      {:telemetry, "~> 0.4.2"},

      # optional
      {:jason, "~> 1.2", optional: true},
      {:finch, "~> 0.5", optional: true},

      # dev/test
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:bypass, "~> 2.1", only: :test},
      {:excoveralls, "~> 0.14.0", only: :test},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:credo_naming, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      main: @name,
      source_ref: "v#{@version}",
      source_url: @repo_url,
      extras: ["CHANGELOG.md"]
    ]
  end

  defp package do
    %{
      licenses: ["Apache-2.0"],
      maintainers: ["Thiago Santos"],
      links: %{"GitHub" => @repo_url}
    }
  end
end
