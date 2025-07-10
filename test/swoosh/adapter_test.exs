defmodule Mailcast.Swoosh.AdapterTest do
  use ExUnit.Case

  test "deliver/2" do
    sham = Sham.start()

    Sham.expect_once(sham, "POST", "/v1/emails", fn conn ->
      conn =
        Plug.Parsers.call(
          conn,
          Plug.Parsers.init(parsers: [:json], json_decoder: Swoosh.json_library())
        )

      assert %{
               "attachments" => [
                 %{
                   "content" => "VGVzdCBEYXRh",
                   "content_type" => "text/plain",
                   "filename" => "test.txt"
                 }
               ],
               "bcc" => "\"BCC Name\" <bcc@example.com>",
               "cc" => "\"CC Name\" <cc@example.com>",
               "from" => "\"From Name\" <from@example.com>",
               "headers" => %{
                 "X-Custom-Header" => "Custom Value",
                 "X-Custom-Header-2" => "Custom Value 2",
                 "X-Custom-Header-3" => "Custom Value 3"
               },
               "html" => "Test HTML Body",
               "reply_to" => "\"Reply To Name\" <reply_to@example.com>",
               "subject" => "Test Subject",
               "text" => "Test Text Body",
               "to" => ["\"To Name 2\" <to2@example.com>", "\"To Name\" <to@example.com>"],
               "tags" => [%{"name" => "tag1", "value" => "value1"}],
               "data" => %{"first_name" => "John", "last_name" => "Doe"},
               "transactional" => true,
               "template_id" => "template_01jzqtmznaexgb9d3rpectx870"
             } = conn.body_params

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        200,
        Swoosh.json_library().encode!(%{email_id: "email_01jzqtmznaexgb9d3rpectx870"})
      )
    end)

    email =
      Swoosh.Email.new()
      |> Swoosh.Email.from({"From Name", "from@example.com"})
      |> Swoosh.Email.to({"To Name", "to@example.com"})
      |> Swoosh.Email.to({"To Name 2", "to2@example.com"})
      |> Swoosh.Email.cc({"CC Name", "cc@example.com"})
      |> Swoosh.Email.bcc({"BCC Name", "bcc@example.com"})
      |> Swoosh.Email.reply_to({"Reply To Name", "reply_to@example.com"})
      |> Swoosh.Email.subject("Test Subject")
      |> Swoosh.Email.html_body("Test HTML Body")
      |> Swoosh.Email.text_body("Test Text Body")
      |> Swoosh.Email.header("X-Custom-Header", "Custom Value")
      |> Swoosh.Email.header("X-Custom-Header-2", "Custom Value 2")
      |> Swoosh.Email.header("X-Custom-Header-3", "Custom Value 3")
      |> Swoosh.Email.put_provider_option(:tags, [%{name: "tag1", value: "value1"}])
      |> Swoosh.Email.put_provider_option(:template_id, "template_01jzqtmznaexgb9d3rpectx870")
      |> Swoosh.Email.put_provider_option(:data, %{first_name: "John", last_name: "Doe"})
      |> Swoosh.Email.put_provider_option(:transactional, true)
      |> Swoosh.Email.attachment(%Swoosh.Attachment{
        filename: "test.txt",
        content_type: "text/plain",
        data: "Test Data"
      })

    assert Mailcast.Swoosh.Adapter.deliver(email,
             base_url: "http://localhost:#{sham.port}"
           ) ==
             {:ok, %{email_id: "email_01jzqtmznaexgb9d3rpectx870"}}

    Process.sleep(100)
  end
end
