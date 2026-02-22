defmodule GoldClaw.Agents.Shadow do
  @moduledoc """
  Jido Shadow agent for representing edge devices in Mothership.

  Matches V3.2 Technical Spec exactly.
  Maintains state for:
  - Agent status (online, offline, error)
  - Last heartbeat timestamp
  - System metrics (CPU, memory, disk)
  - Queue management for outgoing instructions

  Uses Jido.Agent for AI and Action capabilities.
  """
  use Jido.Agent,
    name: "shadow_agent"

  defstruct [
    edge_id: [type: :string, required: true],
    status: [type: :atom, default: :offline],
    last_heartbeat: [type: :string, default: nil],
    cpu_load: [type: :float, default: 0.0],
    memory_mb: [type: :integer, default: 0],
    disk_gb: [type: :float, default: 0.0],
    current_task: [type: :string, default: nil],
    last_error: [type: :string, default: nil]
  ]

  alias Jido.Signal

  @impl true
  def init(_agent, _opts) do
    # Initialize with offline status
    {:ok, %__MODULE__{}}
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

    # Extract agent_id from source URN
    edge_id = extract_edge_id(signal.source)

    # Update state using Jido methods
    new_state = Jido.Agent.update_field(state, :edge_id, edge_id)
    new_state = Jido.Agent.update_field(new_state, :status, data["status"] || :online)
    new_state = Jido.Agent.update_field(new_state, :last_heartbeat, signal.time)
    new_state = Jido.Agent.update_field(new_state, :cpu_load, data["cpu_load"] || 0.0)
    new_state = Jido.Agent.update_field(new_state, :memory_mb, data["memory_mb"] || 0)
    new_state = Jido.Agent.update_field(new_state, :disk_gb, data["disk_gb"] || 0)
    new_state = Jido.Agent.update_field(new_state, :current_task, data["current_task"] || nil)
    new_state = Jido.Agent.update_field(new_state, :last_error, data["last_error"])

    # Log heartbeat
    Jido.Agent.log(new_state, "Heartbeat from #{edge_id} - CPU: #{data["cpu_load"]}%")

    {:ok, new_state}
  end

  # Handle execution result from edge agent
  defp handle_result(signal, state) do
    data = signal.data
    instruction_id = data["instruction_id"]
    status = data["status"]

    # Extract agent_id from source URN
    edge_id = extract_edge_id(signal.source)

    # Update instruction in database
    GoldClaw.Queue.complete_instruction(instruction_id, %{
      status: status,
      output: data["output"],
      error: data["error"],
      duration_ms: data["duration_ms"]
    })

    # Update agent state
    new_state = Jido.Agent.update_field(state, :current_task, :idle)
    new_state = Jido.Agent.update_field(new_state, :last_error, if(status == "failed", do: data["error"], else: nil))

    # Log completion
    Jido.Agent.log(new_state, "Instruction #{instruction_id} completed with status: #{status}")

    {:ok, new_state}
  end

  # Extract agent_id from source URN
  defp extract_edge_id(source) do
    case String.split(source, ":", trim: true) do
      ["urn", "ironclaw", "agent", edge_id] ->
        edge_id
      _ ->
        "unknown"
    end
  end
end
