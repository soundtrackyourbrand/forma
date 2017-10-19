defmodule Forma.Mixfile do
  use Mix.Project

  def project do
    [
      app: :forma,
      name: "forma",
      version: "0.4.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/soundtrackyourbrand/forma",
    ]
  end

  defp description() do
    "Provides structured parsing of JSON-like data based on modules' Typespecs."
  end

  defp package() do
    [
      name: "forma",
      licenses: ["MIT"],
      files: ["lib", "README.md", "LICENSE", "mix.exs"],
      maintainers: ["Fredrik Wärnsberg", "Fredrik Enestad"],
      links: %{"GitHub" => "https://github.com/soundtrackyourbrand/forma"}
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Forma, []}
    ]
  end

  defp elixirc_paths(:ci), do: ["lib", "test/support"]
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  defp deps do
    [
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.16", only: :dev},
    ]
  end
end
