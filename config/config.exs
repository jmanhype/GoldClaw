import Config

config :goldclaw,
  # Mothership URL (set via env var in production)
  mothership_url: System.get_env("MOTHERSHIP_URL", "http://localhost:4000"),

  # Agent secret for HMAC signing (set via env var)
  agent_secret: System.get_env("AGENT_SECRET"),

  # Lease duration in seconds
  lease_duration: 300,

  ecto_repos: [GoldClaw.Repo]

# Database configuration
config :goldclaw, GoldClaw.Repo,
  url: System.get_env("DATABASE_URL", "postgresql://postgres:postgres@localhost/goldclaw"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")