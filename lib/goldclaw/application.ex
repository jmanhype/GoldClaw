defmodule GoldClaw.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Ecto Repository
      GoldClaw.Repo,

      # Registry for Shadow Agent PIDs
      {Registry, keys: :unique, name: GoldClaw.Registry},

      # Dynamic Supervisor for Shadow Agents
      {DynamicSupervisor, name: GoldClaw.AgentSupervisor, strategy: :one_for_one},

      # Goldrush Pre-Filter
      GoldClaw.Filters.Preflight,

      # Instruction Queue (GenServer)
      {GoldClaw.Queue, name: GoldClaw.Queue},

      # Web Endpoint (Plug.Cowboy)
      {Plug.Cowboy, scheme: :http, plug: GoldClawWeb.Router, options: [port: 4000]}
    ]

    opts = [strategy: :one_for_one, name: GoldClaw.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
