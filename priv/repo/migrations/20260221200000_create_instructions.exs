defmodule GoldClaw.Repo.Migrations.CreateInstructions do
  use Ecto.Migration

  def change do
    create table(:instructions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :instruction_id, :string, null: false
      add :agent_id, :string, null: false
      add :status, :string, default: "pending", null: false
      add :payload, :map
      add :leased_until, :utc_datetime
      add :result, :map
      add :completed_at, :utc_datetime
      add :created_at, :utc_datetime, default: fragment("NOW()")
      add :updated_at, :utc_datetime, default: fragment("NOW()")
    end

    create unique_index(:instructions, [:agent_id, :instruction_id], name: :unique_agent_instruction)
    create index(:instructions, [:agent_id, :status])
    create index(:instructions, [:leased_until])
  end
end
