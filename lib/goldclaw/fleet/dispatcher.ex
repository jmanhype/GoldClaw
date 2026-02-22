defmodule GoldClaw.Fleet.Dispatcher do
  @moduledoc """
  Fleet-wide signal dispatcher for routing signals to Shadow agents.

  Handles:
  - Agent ID extraction from URN
  - Dynamic Shadow agent start/get
  - Async signal dispatch via cast
  """
  require Logger

  alias GoldClaw.Agents.Shadow

  @doc """
  Dispatch a signal to the appropriate Shadow agent.
  """
  def dispatch(%Jido.Signal{source: source} = signal) do
    # 1. Extract Agent ID from URN (urn:ironclaw:agent:<UUID>)
    case String.split(source, ":", trim: true) do
      ["urn", "ironclaw", "agent", agent_id] ->
        # 2. Get PID (Get or Start)
        pid = get_or_start_agent(agent_id)

        # 3. Forward Signal (Async CAST to prevent backpressure)
        GenServer.cast(pid, {:signal, signal})

      _ ->
        Logger.error("Invalid source URN: #{source}")
        {:error, :invalid_source}
    end
  end

  defp get_or_start_agent(agent_id) do
    case Registry.lookup(GoldClaw.Registry, agent_id) do
      [{pid, _}] ->
        pid
      [] ->
        start_shadow_agent(agent_id)
    end
  end

  defp start_shadow_agent(agent_id) do
    # Start Shadow agent as GenServer child
    child_spec = %{
      id: {Shadow, agent_id},
      start: {Shadow, :start_link, [[name: via_tuple(GoldClaw.Registry, agent_id)]]},
      restart: :transient
    }

    case DynamicSupervisor.start_child(GoldClaw.AgentSupervisor, child_spec) do
      {:ok, pid} ->
        Logger.info("Started Shadow agent for #{agent_id}")
        pid

      {:error, {:already_started, pid}} ->
        Logger.debug("Shadow agent already exists for #{agent_id}")
        pid

      {:error, reason} ->
        Logger.error("Failed to start Shadow agent for #{agent_id}: #{inspect(reason)}")
        raise "Failed to start Shadow agent: #{inspect(reason)}"
    end
  end

  defp via_tuple(registry, key) do
    {:via, Registry, {registry, key}}
  end
end
