defmodule Simdjsone.MixProject do
  use Mix.Project

  def project do
    [
      app: :simdjsone,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jiffy, "~> 1.1.1"},
      {:jason, "~> 1.4"},
      {:benchee, "~> 1.0", only: :dev},
      {:thoas, "~> 1.0"}
    ]
  end
end
