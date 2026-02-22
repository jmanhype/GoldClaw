defmodule GoldClaw.Agents.Shadow do
  @moduledoc """
  Jido 2.0 Shadow agent for representing edge devices in the Mothership.

  Maintains state for:
  - Agent status (online, offline, error)
  - Last heartbeat timestamp
  - System metrics (CPU, memory, disk)
  - Queue management for outgoing instructions

  Shadow agents are lightweight in-memory representations of edge devices.
  They don't execute code locally — they manage the instruction queue and
  coordinate with the Fleet Dispatcher.
  """
  use Jido.Agent

  defstruct [
    :agent_id,
    status: :offline,
    last_heartbeat: nil,
    cpu_load: 0.0,
    memory_mb: 0,
    disk_gb: 0,
    current_task: :idle,
    last_error: nil
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

    new_state = %__MODULE__{
      state |
      agent_id: signal.subject,
      status: data["status"] || :online,
      last_heartbeat: signal.time,
      cpu_load: data["cpu_load"] || 0.0,
      memory_mb: data["memory_mb"] || 0,
      disk_gb: data["disk_gb"] || 0,
      current_task: data["current_task"] || :idle,
      last_error: data["last_error"]
    }

    # Log status changes
    if new_state.status != state.status do
      Jido.Agent.log(state, "Agent status changed: #{state.status} -> #{new_state.status}")
    end

    {:ok, new_state}
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
    new_state = %__MODULE__{
      state |
      current_task: :idle,
      last_error: if(status == "failed", do: data["error"], else: nil)
    }

    Jido.Agent.log(state, "Instruction #{instruction_id} completed with status: #{status}")

    {:ok, new_state}
  end
end
