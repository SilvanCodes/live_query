defmodule LiveQuery.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_query,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {LiveQuery.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_view, "~> 0.17.11"},
      {:floki, ">= 0.30.0", only: :test},
      {:jason, "~> 1.0", only: :test},
      {:phoenix_pubsub, "~> 2.1.1"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, "~> 0.16"}
    ]
  end
end
