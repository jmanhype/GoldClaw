defmodule GoldClaw.Agents.Shadow do
  @moduledoc """
  Shadow agent for representing edge devices in Mothership.

  Plain GenServer implementation (no Jido.Agent dependency).
  Works with Jido.Signal for data structure but uses GenServer for behavior.

  Maintains state for:
  - Agent status (online, offline, error)
  - Last heartbeat timestamp
  - Current task
  """
  use GenServer

  defstruct [
    :name,
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
  def init(_opts) do
    # Initialize with offline status
    {:ok, %__MODULE__{status: :offline}}
  end

  @impl true
  def handle_cast({:signal, signal}, state) do
    case signal do
      %{type: "com.cybernetic.agent.heartbeat"} ->
        handle_heartbeat(signal, state)

      %{type: "com.cybernetic.agent.result"} ->
        handle_result(signal, state)

      _ ->
        {:noreply, state}
    end
  end

  # Handle heartbeat from edge agent
  defp handle_heartbeat(signal, state) do
    data = signal.data

    # Extract agent_id from source URN for logging
    agent_id = extract_agent_id(signal.source)

    # Update state
    new_state = %__MODULE__{
      state |
      name: agent_id,
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
      IO.puts("[Shadow #{agent_id}] status changed: #{state.status} -> #{new_state.status}")
    end

    {:noreply, new_state}
  end

  # Handle execution result from edge agent
  defp handle_result(signal, state) do
    data = signal.data
    instruction_id = data["instruction_id"]
    status = data["status"]

    # Extract agent_id for logging
    agent_id = extract_agent_id(signal.source)

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

    IO.puts("[Shadow #{agent_id}] completed instruction #{instruction_id} with status: #{status}")

    {:noreply, new_state}
  end

  # Extract agent_id from source URN: urn:ironclaw:agent:<UUID>
  defp extract_agent_id(source) do
    case String.split(source, ":", trim: true) do
      ["urn", "ironclaw", "agent", agent_id] -> agent_id
      _ -> "unknown"
    end
  end
end
