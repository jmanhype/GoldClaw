defmodule GoldClaw.Agents.Shadow do
  @moduledoc """
  Jido Shadow agent for representing edge devices in Mothership.

  Matches V3.2 Technical Spec exactly.
  """
  use Jido.Agent

  defstruct [
    edge_id: [type: :string, required: true],
    status: [type: :atom, default: :offline],
    last_heartbeat: [type: :string],
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
    {:ok, %__MODULE__{edge_id: nil}}
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

    # Update state using Jido methods
    state = Jido.Agent.update_field(state, :edge_id, signal.subject)
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
