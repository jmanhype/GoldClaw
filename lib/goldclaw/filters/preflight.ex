defmodule GoldClaw.Filters.Preflight do
  @moduledoc """
  Goldrush-powered pre-filter for heartbeat signals.

  Only dispatches significant events to the Fleet Dispatcher:
  - CPU load > 90%
  - Status != "online"

  This prevents noisy heartbeat storms and reduces dispatcher load.
  """
  use GenServer

  @filter_module :goldclaw_preflight_filter

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # Compile Goldrush match spec
    compile_filter()
    {:ok, %{}}
  end

  @doc """
  Compile the Goldrush filter at startup.
  """
  def compile_filter do
    # Logic: Wake up if CPU > 90% OR Status != "online"
    query = :glc.any([
      :glc.gt(:cpu_load, 0.90),
      :glc.neq(:status, "online")
    ])

    :glc.compile(@filter_module, :glc.with(query, &dispatch/1))
  end

  @doc """
  Ingest a signal into the pre-filter.
  """
  def ingest(%Jido.Signal{} = signal) do
    # Convert Signal Data to Flat Goldrush Event
    event = :gre.make(
      [
        cpu_load: signal.data["cpu_load"] || 0.0,
        status: signal.data["status"] || "unknown",
        signal: signal # Pass the full signal through as payload
      ],
      [:list] # Optimization: Use list-backed event
    )

    :glc.handle(@filter_module, event)
  end

  defp dispatch(event) do
    # Extract the original signal
    signal = :gre.fetch(:signal, event)
    GoldClaw.Fleet.Dispatcher.dispatch(signal)
  end
end
