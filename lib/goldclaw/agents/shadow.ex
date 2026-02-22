defmodule GoldClaw.Agents.Shadow do
  @moduledoc """
  Jido Shadow agent for representing edge devices in Mothership.

  Matches V3.2 Technical Spec exactly.
  Uses `:name` field to satisfy Jido.Agent validation.
  Extracts `:agent_id` from source URN for logging.

  Maintains state for:
  - Agent status (online, offline, error)
  - Last heartbeat timestamp
  - Current task
  """
  use Jido.Agent

  # V3.2 Spec: Extract agent_id from source URN
  defstruct [
    :name,           # Required by Jido.Agent
    :agent_id,       # Derived from signal source
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
    {:ok, %__MODULE__{name: nil, status: :offline}}
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

    # Extract agent_id from source URN for logging
    agent_id = extract_agent_id(signal.source)

    # Update state using Jido methods
    state = Jido.Agent.update_field(state, :name, agent_id)
    state = Jido.Agent.update_field(state, :status, data["status"] || :online)
    state = Jido.Agent.update_field(state, :last_heartbeat, signal.time)
    state = Jido.Agent.update_field(state, :cpu_load, data["cpu_load"] || 0.0)
    state = Jido.Agent.update_field(state, :memory_mb, data["memory_mb"] || 0)
    state = Jido.Agent.update_field(state, :disk_gb, data["disk_gb"] || 0)
    state = Jido.Agent.update_field(state, :current_task, data["current_task"] || nil)
    state = Jido.Agent.update_field(state, :last_error, data["last_error"])

    # Log status changes
    old_status = Jido.Agent.get_field(state, :status)
    if old_status != Jido.Agent.get_field(state, :status) do
      Jido.Agent.log(state, "Agent #{agent_id} status changed: #{old_status} -> #{Jido.Agent.get_field(state, :status)}")
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

    Jido.Agent.log(state, "Agent #{state.name} completed instruction #{instruction_id} with status: #{status}")

    {:ok, state}
  end

  # Extract agent_id from source URN: urn:ironclaw:agent:<UUID>
  defp extract_agent_id(source) do
    case String.split(source, ":", trim: true) do
      ["urn", "ironclaw", "agent", agent_id] -> agent_id
      _ -> "unknown"
    end
  end
end
