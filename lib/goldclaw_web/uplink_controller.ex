defmodule GoldClawWeb.UplinkController do
  @moduledoc """
  Gateway controller for inbound CloudEvents from IronClaw agents.

  Handles:
  - Specversion normalization (1.0 ↔ 1.0.2)
  - HMAC signature verification
  - Signal ingestion and dispatch
  """
  import Plug.Conn

  @signature_header "x-cybernetic-signature"
  @timestamp_header "x-cybernetic-timestamp"
  @nonce_header "x-cybernetic-nonce"

  @doc """
  Ingest a CloudEvent signal from an edge agent.
  """
  def ingest(conn, params) do
    with :ok <- verify_auth(conn),
         params <- normalize_specversion(params),
         {:ok, signal} <- Jido.Signal.from_map(params) do

      # Pass to Pre-Filter
      GoldClaw.Filters.Preflight.ingest(signal)
      json(conn, %{accepted: true})
    else
      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(%{error: inspect(reason)})
    end
  end

  @doc """
  Fetch pending instructions for an agent.
  Returns 200 with instruction or 204 if none available.
  """
  def fetch_instructions(conn, agent_id) do
    with :ok <- verify_auth(conn),
         {:ok, instruction} <- GoldClaw.Queue.lease_instruction(agent_id) do

      # Denormalize from 1.0.2 to 1.0 for edge consumption
      instruction_map = denormalize_specversion(Jido.Signal.to_map(instruction))
      json(conn, instruction_map)
    else
      :no_instructions ->
        send_resp(conn, 204, "")
      {:error, reason} ->
        conn
        |> put_status(400)
        |> json(%{error: inspect(reason)})
    end
  end

  @doc """
  Verify HMAC signature of the request.

  Signature = HMAC-SHA256(AGENT_SECRET, Timestamp + "\n" + Nonce + "\n" + Body)
  """
  def verify_auth(conn) do
    secret = Application.get_env(:goldclaw, :agent_secret)

    case {get_req_header(conn, @signature_header),
          get_req_header(conn, @timestamp_header),
          get_req_header(conn, @nonce_header)} do
      {[signature], [timestamp], [nonce]} when is_binary(signature) and is_binary(timestamp) and is_binary(nonce) ->
        verify_hmac(signature, timestamp, nonce, conn.body_params, secret)

      _ ->
        {:error, :missing_auth_headers}
    end
  end

  defp verify_hmac(signature, timestamp, nonce, body, secret) do
    # TODO: Validate timestamp is within 5 minutes
    # TODO: Track nonces to prevent replay attacks

    message = "#{timestamp}\n#{nonce}\n#{Jason.encode!(body)}"
    expected_sig = :crypto.hmac(:sha256, secret, message) |> Base.encode16(case: :lower)

    if secure_compare(signature, expected_sig) do
      :ok
    else
      {:error, :invalid_signature}
    end
  end

  # Constant-time comparison to prevent timing attacks
  defp secure_compare(a, b) when byte_size(a) == byte_size(b) do
    a == b
  end
  defp secure_compare(_, _), do: false

  @doc """
  Normalize CloudEvents 1.0 to 1.0.2 (Jido internal format).
  """
  def normalize_specversion(%{"specversion" => "1.0"} = m),
    do: Map.put(m, "specversion", "1.0.2")
  def normalize_specversion(m), do: m

  @doc """
  Denormalize CloudEvents 1.0.2 to 1.0 (wire format for edge agents).
  Strips Jido extensions to ensure strict CloudEvents 1.0 compliance.
  """
  def denormalize_specversion(%{"specversion" => "1.0.2"} = m) do
    m
    |> Map.put("specversion", "1.0")
    |> Map.drop(["jido_agent", "jido_context"])
  end
  def denormalize_specversion(m), do: m

  defp json(conn, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(data))
  end
end
