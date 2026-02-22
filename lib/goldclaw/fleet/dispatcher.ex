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
  alias Jido.Agent.Server

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
        Server.cast(pid, signal)

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
    # Correct Jido 2.0 start_child pattern
    case DynamicSupervisor.start_child(
           GoldClaw.AgentSupervisor,
           {Server, agent: Shadow, id: agent_id, registry: GoldClaw.Registry}
         ) do
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
end
