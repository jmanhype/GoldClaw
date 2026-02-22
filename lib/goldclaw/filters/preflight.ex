defmodule GoldClaw.Filters.Preflight do
  @moduledoc """
  Pre-filter for heartbeat signals.

  Only dispatches significant events to the Fleet Dispatcher:
  - CPU load > 90%
  - Status != "online"

  This prevents noisy heartbeat storms and reduces dispatcher load.

  Note: Simplified implementation without Goldrush for OTP 28 compatibility.
  """
  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    {:ok, %{}}
  end

  @doc """
  Ingest a signal into the pre-filter.
  """
  def ingest(%Jido.Signal{type: "com.cybernetic.agent.heartbeat"} = signal) do
    cpu_load = signal.data["cpu_load"] || 0.0
    status = signal.data["status"] || "unknown"

    # Logic: Wake up if CPU > 90% OR Status != "online"
    if should_dispatch?(cpu_load, status) do
      GoldClaw.Fleet.Dispatcher.dispatch(signal)
    end

    :ok
  end

  def ingest(%Jido.Signal{} = signal) do
    # Non-heartbeat signals always dispatch
    GoldClaw.Fleet.Dispatcher.dispatch(signal)
  end

  defp should_dispatch?(cpu_load, status) do
    cpu_load > 0.90 or status != "online"
  end
end
