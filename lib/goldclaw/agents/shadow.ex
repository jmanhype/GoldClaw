defmodule GoldClaw.Agents.Shadow do
  @moduledoc """
  Jido Shadow agent for representing edge devices in Mothership.

  Uses Jido.Agent for AI and Action capabilities.
  """
  use Jido.Agent

  defstruct [
    :agent_id,
    :status,
    :last_heartbeat,
    :cpu_load,
    :memory_mb,
    :disk_gb,
    :current_task,
    :last_error
  ]

  alias Jido.Signal

  @impl true
  def init(_agent, _opts) do
    # Initialize with offline status
    Jido.Agent.init_state(__MODULE__)
  end

  @impl true
  def handle_signal(signal, state) do
    case signal do
      %{type: "com.cybernetic.agent.heartbeat"} ->
        handle_heartbeat(signal, state)

      %{type: "com.cybernetic.agent.result"} ->
        handle_result(signal, state)

      _ ->
        {:ok, state}
    end
  end

  # Handle heartbeat from edge agent
  defp handle_heartbeat(signal, state) do
    data = signal.data

    # Update agent state using Jido methods
    state = Jido.Agent.update_field(state, :edge_id, signal.subject)
    state = Jido.Agent.update_field(state, :status, data["status"] || :online)
    state = Jido.Agent.update_field(state, :last_heartbeat, signal.time)
    state = Jido.Agent.update_field(state, :cpu_load, data["cpu_load"] || 0.0)
    state = Jido.Agent.update_field(state, :memory_mb, data["memory_mb"] || 0)
    state = Jido.Agent.update_field(state, :disk_gb, data["disk_gb"] || 0)
    state = Jido.Agent.update_field(state, :current_task, data["current_task"] || :idle)
    state = Jido.Agent.update_field(state, :last_error, data["last_error"])

    # Log status changes
    old_status = Jido.Agent.get_field(state, :status)
    if old_status != Jido.Agent.get_field(state, :status) do
      Jido.Agent.log(state, "Agent status changed: #{old_status} -> #{Jido.Agent.get_field(state, :status)}")
    end

    {:ok, state}
  end

  # Handle execution result from edge agent
  defp handle_result(signal, state) do
    data = signal.data
    instruction_id = data["instruction_id"]
    status = data["status"]

    # Update instruction in database
    GoldClaw.Queue.complete_instruction(instruction_id, %{
      status: status,
      output: data["output"],
      error: data["error"],
      duration_ms: data["duration_ms"]
    })

    # Update agent state
    state = Jido.Agent.update_field(state, :current_task, :idle)
    state = Jido.Agent.update_field(state, :last_error, if(status == "failed", do: data["error"], else: nil))

    Jido.Agent.log(state, "Instruction #{instruction_id} completed with status: #{status}")

    {:ok, state}
  end
end
