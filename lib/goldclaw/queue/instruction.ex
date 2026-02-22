defmodule GoldClaw.Queue.Instruction do
  @moduledoc """
  Ecto schema for instruction records.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "instructions" do
    field :instruction_id, :string
    field :agent_id, :string
    field :status, :string, default: "pending"
    field :payload, :map
    field :leased_until, :utc_datetime
    field :result, :map
    field :completed_at, :utc_datetime
    field :created_at, :utc_datetime
    field :updated_at, :utc_datetime
  end

  def changeset(instruction, attrs) do
    instruction
    |> cast(attrs, [:instruction_id, :agent_id, :status, :payload, :leased_until, :result, :completed_at])
    |> validate_required([:instruction_id, :agent_id, :status])
    |> validate_inclusion(:status, ["pending", "leased", "completed", "failed"])
    |> unique_constraint([:agent_id, :instruction_id], name: :unique_agent_instruction)
  end

  @doc """
  Create a new instruction.
  """
  def create(agent_id, payload) do
    instruction_id = "inst-#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}"

    %__MODULE__{}
    |> changeset(%{
      instruction_id: instruction_id,
      agent_id: agent_id,
      status: "pending",
      payload: payload,
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now()
    })
    |> GoldClaw.Repo.insert()
  end

  @doc """
  Atomically lease a pending instruction.
  Returns :no_instructions if no pending instructions available.
  """
  def lease(agent_id) do
    now = DateTime.utc_now()
    lease_duration = Application.get_env(:goldclaw, :lease_duration, 300)

    from(i in __MODULE__,
      where: i.agent_id == ^agent_id and i.status == "pending",
      limit: 1
    )
    |> GoldClaw.Repo.one()
    |> case do
      nil ->
        :no_instructions

      instruction ->
        leased_until = DateTime.add(now, lease_duration, :second)

        # Atomic update to leased status
        instruction
        |> changeset(%{
          status: "leased",
          leased_until: leased_until,
          updated_at: DateTime.utc_now()
        })
        |> GoldClaw.Repo.update()
        |> case do
          {:ok, updated} -> {:ok, updated}
          {:error, _} -> :no_instructions
        end
    end
  end

  @doc """
  Mark an instruction as completed.
  Idempotent: accepts duplicate results for the same instruction_id.
  """
  def complete(instruction_id, result) do
    now = DateTime.utc_now()

    from(i in __MODULE__,
      where: i.instruction_id == ^instruction_id and i.status in ["leased", "completed"]
    )
    |> GoldClaw.Repo.one()
    |> case do
      nil ->
        {:error, :not_found}

      %{status: "completed"} = instruction ->
        # Duplicate result, accept without updating
        {:ok, instruction}

      instruction ->
        instruction
        |> changeset(%{
          status: "completed",
          result: result,
          completed_at: now,
          updated_at: now
        })
        |> GoldClaw.Repo.update()
    end
  end

  @doc """
  Reap expired leases (stuck lease cleanup).
  Resets leased instructions with expired leases back to pending.
  """
  def reap_expired_leases do
    now = DateTime.utc_now()

    from(i in __MODULE__,
      where: i.status == "leased" and i.leased_until < ^now
    )
    |> GoldClaw.Repo.update_all(set: [
      status: "pending",
      leased_until: nil,
      updated_at: now
    ])
  end
end
