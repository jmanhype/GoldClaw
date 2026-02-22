import Config

config :goldclaw,
  # Mothership URL (set via env var in production)
  mothership_url: System.get_env("MOTHERSHIP_URL", "http://localhost:4000"),

  # Agent secret for HMAC signing (set via env var)
  agent_secret: System.get_env("AGENT_SECRET"),

  # Lease duration in seconds
  lease_duration: 300
