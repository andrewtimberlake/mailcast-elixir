defmodule Mailcast.Client do
  @moduledoc """
  HTTP client for the Mailcast API.

  ## Configuration

      config :mailcast,
        api_key: "prod_...",
        base_url: "https://api.mailcast.io"

  Options passed to request functions override application config:

    * `:api_key` - Bearer token. Required unless set in application env.
    * `:base_url` - API host, without a path. Defaults to `https://api.mailcast.io`.

  Requires the optional [`Req`](https://hex.pm/packages/req) dependency.
  """

  @default_base_url "https://api.mailcast.io"

  @doc false
  def get(path, opts \\ []) do
    request(:get, path, opts)
  end

  @doc false
  def post(path, body, opts \\ []) do
    request(:post, path, Keyword.put(opts, :json, body))
  end

  @doc false
  def patch(path, body, opts \\ []) do
    request(:patch, path, Keyword.put(opts, :json, body))
  end

  @doc false
  def delete(path, opts \\ []) do
    request(:delete, path, opts)
  end

  defp request(method, path, opts) do
    ensure_req!()

    {body, opts} = Keyword.pop(opts, :json)

    req_opts = [
      method: method,
      url: url(path, opts),
      headers: headers(opts)
    ]

    req_opts =
      if body do
        Keyword.put(req_opts, :json, json_body(body))
      else
        req_opts
      end

    case Req.request(req_opts) do
      {:ok, %{status: status, body: response_body}} when status in 200..299 ->
        {:ok, normalize_body(response_body)}

      {:ok, %{status: status, body: response_body}} ->
        {:error, {status, response_body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp url(path, opts) do
    opts
    |> base_url()
    |> URI.merge(path)
    |> URI.to_string()
  end

  defp headers(opts) do
    [
      {"authorization", "Bearer #{api_key(opts)}"},
      {"user-agent", user_agent()},
      {"accept", "application/json"}
    ]
  end

  defp api_key(opts) do
    Keyword.get_lazy(opts, :api_key, fn ->
      Application.get_env(:mailcast, :api_key) || raise "Supply a Mailcast API key"
    end)
  end

  defp base_url(opts) do
    Keyword.get_lazy(opts, :base_url, fn ->
      Application.get_env(:mailcast, :base_url) || @default_base_url
    end)
  end

  defp user_agent do
    "mailcast-elixir/#{Application.spec(:mailcast, :vsn)}"
  end

  defp json_body(body) when is_list(body), do: Map.new(body)
  defp json_body(body), do: body

  defp normalize_body(""), do: nil
  defp normalize_body(body), do: body

  defp ensure_req! do
    if !Code.ensure_loaded?(Req) do
      raise """
      Mailcast API calls require the optional Req dependency.

          {:req, "~> 0.5"}

      Add it to your mix.exs dependencies.
      """
    end
  end
end
