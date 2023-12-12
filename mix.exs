defmodule Qry.MixProject do
  use Mix.Project

  def project do
    [
      app: :qry,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Simple query language for Elixir.",
      package: package()
    ]
  end

  def application do
    []
  end

  defp deps do
    []
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: []
    ]
  end
end
