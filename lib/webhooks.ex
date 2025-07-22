defmodule Mailcast.Webhooks do
  def verify_signature(conn, raw_body \\ nil) do
    secret = Application.fetch_env!(:mailcast, :webhook_secret)

    raw_body = get_raw_body(conn, raw_body)

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
