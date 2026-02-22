defmodule GoldClaw.Agents.Shadow do
  @moduledoc """
  Jido Shadow agent for representing edge devices in Mothership.

  Matches the exact specification from V3.2 Technical Spec, Section 7.

  Maintains state for:
  - Agent status (online, offline, error)
  - CPU history for telemetry
  - Instruction queue coordination

  Uses Jido.Agent for AI and Action capabilities.
  """
  use Jido.Agent,
    name: "shadow_agent",
    description: "The cloud-brain for a physical IronClaw node",
    schema: [
      edge_id: [type: :string, required: true],
      status: [type: :atom, default: :offline],
      cpu_history: [type: {:array, :float}, default: []]
    ]

  alias Jido.Signal

  @impl true
  def init(_agent, _opts) do
    # Initialize with offline status and empty CPU history
    {:ok, Jido.Agent.init_state(__MODULE__, [])}
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
    cpu_load = data["cpu_load"] || 0.0

    # Update state using Jido.Agent methods
    state = Jido.Agent.update_field(state, :edge_id, signal.subject)
    state = Jido.Agent.update_field(state, :status, data["status"] || :online)
    
    # Update CPU history
    current_history = Jido.Agent.get_field(state, :cpu_history)
    new_history = current_history ++ [cpu_load]
    
    # Keep only last 100 CPU readings
    final_history = if length(new_history) > 100 do
      Enum.take(new_history, -100)
    else
      new_history
    end
    state = Jido.Agent.update_field(state, :cpu_history, final_history)

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

    # Log completion
    Jido.Agent.log(state, "Instruction #{instruction_id} completed with status: #{status}")

    {:ok, state}
  end
end
