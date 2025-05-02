defmodule Gitlabor.MixProject do
  use Mix.Project

  def project do
    [
      app: :gitlabor,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      # Web UI testing framework, requires chromedriver
      {:wallaby, "~> 0.30", runtime: false, only: :test},

      # For generating unique branch IDs
      {:uuid, "~> 1.1", runtime: false, only: :test},

      # For HTTP(S) requests, against vault mostly
      {:tesla, "~> 1.11"},
      # Required by tesla JSON middleware
      {:jason, "~> 1.4"},
      # Required by tesla Mint adapter
      {:mint, "~> 1.0"}
    ]
  end
end
