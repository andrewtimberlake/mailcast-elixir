defmodule Mailcast.Webhooks do
  @doc """
  Verify the signature of a Mailcast webhook.

  ## Options

  - `:secret` - The webhook secret to use. If not provided, the secret will be fetched from the `:mailcast, :webhook_secret` application environment. If not provided and the secret is not set in the application environment, an error will be raised.
  - `:raw_body` - The raw body of the webhook. If not provided, the body will be fetched from the `:raw_body` assign in the connection. If not provided and the body is not set in the connection, an error will be raised.
  """
  def verify_signature(%Plug.Conn{} = conn, opts \\ []) do
    secret = get_secret(opts)

    raw_body = get_raw_body(conn, Keyword.get(opts, :raw_body))

    with [timestamp] <- Plug.Conn.get_req_header(conn, "x-mailcast-timestamp"),
         [signature] <- Plug.Conn.get_req_header(conn, "x-mailcast-signature") do
      signed_content = Enum.join([timestamp, raw_body], "\n")

      if Plug.Crypto.secure_compare(
           signature,
           Base.encode64(:crypto.mac(:hmac, :sha256, Base.decode64!(secret, padding: false), signed_content))
         ) do
        :ok
      else
        {:error, "Invalid signature"}
      end
    else
      [] ->
        {:error, "Missing header"}

      _ ->
        {:error, "Invalid signature"}
    end
  end

  @doc """
  Generate a signature for a Mailcast webhook.
  This is useful for generating a text request to the webhook endpoint.

  ## Parameters

  - `secret` - The webhook secret to use.
  - `timestamp` - The timestamp of the webhook.
  - `raw_body` - The raw body of the webhook.
  """
  def generate_signature(timestamp, raw_body, opts \\ []) do
    secret = get_secret(opts)

    Base.encode64(
      :crypto.mac(:hmac, :sha256, Base.decode64!(secret, padding: false), Enum.join([timestamp, raw_body], "\n"))
    )
  end

  defp get_secret(opts) do
    Keyword.get_lazy(opts, :secret, fn ->
      Application.get_env(:mailcast, :webhook_secret) || raise "Supply a webhook secret"
    end)
  end

  defp get_raw_body(conn, nil) do
    if raw_body = conn.assigns[:raw_body] do
      raw_body
    else
      raise """
      Cannot verify signature without the raw body.
      See: https://hexdocs.pm/plug/Plug.Parsers.html#module-custom-body-reader
      """
    end
  end

  defp get_raw_body(_conn, raw_body), do: raw_body
end
