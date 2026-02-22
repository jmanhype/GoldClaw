defmodule GoldClaw.MixProject do
  use Mix.Project

  def project do
    [
      app: :goldclaw,
      version: "3.2.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      mod: {GoldClaw.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:jido, "~> 2.0.0-rc"},
      {:cloudevents, "~> 0.6"},
      {:goldrush, "~> 0.1.9"},
      {:plug_cowboy, "~> 2.0"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.30", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      test: ["test --trace"]
    ]
  end
end
