defmodule Mxpanel.MixProject do
  use Mix.Project

  @name "Mxpanel"
  @version "1.0.1"
  @description "Client for Mixpanel Ingestion API"
  @repo_url "https://github.com/thiamsantos/mxpanel"

  def project do
    [
      app: :mxpanel,
      version: @version,
      elixir: "~> 1.7",
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
      {:nimble_options, "~> 0.5.0"},
      {:telemetry, "~> 0.4.2"},

      # optional
      {:hackney, "~> 1.17", optional: true},
      {:jason, "~> 1.2", optional: true},

      # dev/test
      {:bypass, "~> 2.1", only: :test},
      {:credo_naming, "~> 2.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:excoveralls, "~> 0.15.0", only: :test},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  defp docs do
    [
      main: @name,
      source_ref: "v#{@version}",
      source_url: @repo_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
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
