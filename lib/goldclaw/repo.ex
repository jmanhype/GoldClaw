defmodule GoldClaw.Repo do
  @moduledoc """
  Ecto repository for GoldClaw.
  """
  use Ecto.Repo,
    otp_app: :goldclaw,
    adapter: Ecto.Adapters.Postgres
end
