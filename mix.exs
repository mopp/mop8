defmodule Mop8.MixProject do
  use Mix.Project

  def project do
    [
      app: :mop8,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Mop8.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.8"},
      {:poison, "~> 3.1"},
      {:slack, "~> 0.23.5"},
      {:websockex, "~> 0.4.3"},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false}
    ]
  end
end
