defmodule Forma.Mixfile do
  use Mix.Project

  def project do
    [
      app: :forma,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env == :prod,
      deps: deps(),
      package: package(),
    ]
  end

  defp package() do
    [
      name: "forma",
      organization: "Soundtrack Your Brand",
      licenses: ["MIT"],
      files: ["lib", "README.md", "LICENSE", "mix.exs", "priv"],
      maintainers: ["Fredrik Wärnsberg"],
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
    ]
  end
end
