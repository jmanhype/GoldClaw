defmodule GoldClaw.Queue do
  @moduledoc """
  Instruction queue for managing commands to edge agents.

  Handles:
  - Instruction creation and storage
  - Atomic leasing (prevents duplicate dispatch)
  - Lease expiration (stuck lease cleanup)
  - Result recording and idempotency

  Uses Ecto for persistence.
  """
  use GenServer
  require Logger
  alias Jido.Signal

  defstruct []

  # Client API

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Create a new instruction for an agent.
  """
  def create_instruction(agent_id, payload) do
    GoldClaw.Queue.Instruction.create(agent_id, payload)
  end

  @doc """
  Lease a pending instruction for an agent.
  Returns :no_instructions if none available.
  """
  def lease_instruction(agent_id) do
    case GoldClaw.Queue.Instruction.lease(agent_id) do
      {:ok, instruction} ->
        # Convert to Jido Signal
        signal = Jido.Signal.new(%{
          specversion: "1.0.2",
          type: "com.cybernetic.agent.instruction",
          source: "urn:jido:mothership",
          subject: instruction.instruction_id,
          id: generate_id(),
          time: DateTime.utc_now() |> DateTime.to_iso8601(),
          data: instruction.payload
        })
        {:ok, signal}

      :no_instructions ->
        :no_instructions
    end
  end

  @doc """
  Mark an instruction as completed.
  """
  def complete_instruction(instruction_id, result) do
    GoldClaw.Queue.Instruction.complete(instruction_id, result)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    # Start lease reaper (runs every 60 seconds)
    schedule_lease_reap()
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_info(:reap_expired_leases, state) do
    GoldClaw.Queue.Instruction.reap_expired_leases()
    schedule_lease_reap()
    {:noreply, state}
  end

  defp schedule_lease_reap do
    # Reap every 60 seconds
    Process.send_after(self(), :reap_expired_leases, 60_000)
  end

  defp generate_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end
