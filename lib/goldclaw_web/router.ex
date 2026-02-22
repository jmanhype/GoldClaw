defmodule GoldClawWeb.Router do
  @moduledoc """
  Phoenix-style router for the Mothership Gateway.
  """
  use Plug.Router

  plug Plug.Logger
  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch

  # Health check endpoint
  get "/api/health" do
    send_resp(conn, 200, Jason.encode!(%{status: "healthy", version: "3.2.0"}))
  end

  post "/api/signals" do
    GoldClawWeb.UplinkController.ingest(conn, conn.body_params)
  end

  get "/api/instructions/:agent_id" do
    GoldClawWeb.UplinkController.fetch_instructions(conn, agent_id)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
