defmodule SendingTest do
  use ExUnit.Case

  alias Mailcast.Swoosh.Adapter
  alias Swoosh.Email

  @domains [
    "mailcast.email",
    "mailcast.blue",
    "sendosaurus.com",
    "aliveyouth.online",
    "perfectpicture.co.za"
  ]

  @count 1000
  @sender "noreply@mailcast.email"
  @api_key "prod_cdhuuxosfysbe5pyrlsxpy4dyz4agjetvmwiextbzo7o2"

  defp random_string(bytes) do
    :crypto.strong_rand_bytes(bytes)
    |> Base.url_encode64(padding: false)
  end

  @tag timeout: 300_000
  @tag :skip
  test "sends @count emails per domain concurrently", %{timeout: timeout} do
    tasks =
      Enum.map(@domains, fn domain ->
        Task.async(fn ->
          Enum.chunk_every(1..@count, 25)
          |> Enum.map(fn chunk ->
            emails =
              for i <- chunk do
                local_part = "user#{i}"
                recipient = "#{local_part}@#{domain}"

                Email.new()
                |> Email.from(@sender)
                |> Email.to(recipient)
                |> Email.subject("subject-#{i}")
                |> Email.text_body("body-#{random_string(16)}")
              end

            assert {:ok, responses} = Adapter.deliver_many(emails, api_key: @api_key)
            assert length(responses) == length(emails)

            IO.write("+")
          end)
        end)
      end)

    _results = Task.await_many(tasks, timeout)
    IO.puts("done")
  end
end
