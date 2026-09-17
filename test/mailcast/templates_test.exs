defmodule Mailcast.TemplatesTest do
  use ExUnit.Case

  alias Mailcast.Templates

  @api_key "prod_test_key"
  @template_id "template_01jzqtmznaexgb9d3rpectx870"

  @template %{
    "template_id" => @template_id,
    "name" => "welcome",
    "mjml" =>
      "<mjml><mj-body><mj-section><mj-column><mj-text>Hello {{name}}</mj-text></mj-column></mj-section></mj-body></mjml>",
    "from" => "hello@example.com",
    "to" => nil,
    "subject" => "Welcome {{name}}",
    "test_only" => false,
    "created_at" => "2025-08-29T12:00:00Z",
    "updated_at" => "2025-08-29T12:00:00Z"
  }

  setup do
    sham = Sham.start()
    opts = [api_key: @api_key, base_url: "http://localhost:#{sham.port}"]

    %{opts: opts, sham: sham}
  end

  test "create/2 posts a template", %{opts: opts, sham: sham} do
    Sham.expect_once(sham, "POST", "/v1/templates", fn conn ->
      conn = parse_json(conn)

      assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer #{@api_key}"]

      assert %{
               "name" => "welcome",
               "mjml" => mjml,
               "from" => "hello@example.com",
               "subject" => "Welcome {{name}}"
             } = conn.body_params

      assert mjml =~ "{{name}}"

      json_resp(conn, 201, @template)
    end)

    assert {:ok, @template} =
             Templates.create(
               %{
                 name: "welcome",
                 mjml:
                   "<mjml><mj-body><mj-section><mj-column><mj-text>Hello {{name}}</mj-text></mj-column></mj-section></mj-body></mjml>",
                 from: "hello@example.com",
                 subject: "Welcome {{name}}"
               },
               opts
             )
  end

  test "create/2 accepts content instead of mjml", %{opts: opts, sham: sham} do
    Sham.expect_once(sham, "POST", "/v1/templates", fn conn ->
      conn = parse_json(conn)

      assert %{"name" => "plain", "content" => "Hello {{name}}"} = conn.body_params

      template =
        @template
        |> Map.put("name", "plain")
        |> Map.put("content", "Hello {{name}}")
        |> Map.delete("mjml")

      json_resp(conn, 201, template)
    end)

    assert {:ok, %{"name" => "plain", "content" => "Hello {{name}}"}} =
             Templates.create(%{name: "plain", content: "Hello {{name}}"}, opts)
  end

  test "list/1 gets templates", %{opts: opts, sham: sham} do
    Sham.expect_once(sham, "GET", "/v1/templates", fn conn ->
      assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer #{@api_key}"]

      json_resp(conn, 200, %{"templates" => [@template]})
    end)

    assert {:ok, %{"templates" => [@template]}} = Templates.list(opts)
  end

  test "get/2 fetches a template by id", %{opts: opts, sham: sham} do
    Sham.expect_once(sham, "GET", "/v1/templates/#{@template_id}", fn conn ->
      json_resp(conn, 200, @template)
    end)

    assert {:ok, @template} = Templates.get(@template_id, opts)
  end

  test "update/3 patches a template", %{opts: opts, sham: sham} do
    updated = %{
      @template
      | "name" => "welcome-updated",
        "subject" => "Hi {{name}}",
        "updated_at" => "2025-08-29T13:30:00Z"
    }

    Sham.expect_once(sham, "PATCH", "/v1/templates/#{@template_id}", fn conn ->
      conn = parse_json(conn)

      assert %{"name" => "welcome-updated", "subject" => "Hi {{name}}"} = conn.body_params

      json_resp(conn, 200, updated)
    end)

    assert {:ok, ^updated} =
             Templates.update(
               @template_id,
               %{name: "welcome-updated", subject: "Hi {{name}}"},
               opts
             )
  end

  test "delete/2 deletes a template", %{opts: opts, sham: sham} do
    Sham.expect_once(sham, "DELETE", "/v1/templates/#{@template_id}", fn conn ->
      Plug.Conn.resp(conn, 204, "")
    end)

    assert {:ok, nil} = Templates.delete(@template_id, opts)
  end

  test "returns api errors", %{opts: opts, sham: sham} do
    Sham.expect_once(sham, "POST", "/v1/templates", fn conn ->
      json_resp(conn, 422, %{"error" => "must have either mjml or content"})
    end)

    assert {:error, {422, %{"error" => "must have either mjml or content"}}} =
             Templates.create(%{name: "welcome"}, opts)
  end

  test "returns forbidden errors", %{opts: opts, sham: sham} do
    Sham.expect_once(sham, "PATCH", "/v1/templates/#{@template_id}", fn conn ->
      json_resp(conn, 403, %{"error" => "Production templates cannot be modified with a test API key"})
    end)

    assert {:error, {403, %{"error" => "Production templates cannot be modified with a test API key"}}} =
             Templates.update(@template_id, %{subject: "Hi"}, opts)
  end

  test "uses application env for api_key and base_url", %{sham: sham} do
    Application.put_env(:mailcast, :api_key, @api_key)
    Application.put_env(:mailcast, :base_url, "http://localhost:#{sham.port}")

    on_exit(fn ->
      Application.delete_env(:mailcast, :api_key)
      Application.delete_env(:mailcast, :base_url)
    end)

    Sham.expect_once(sham, "GET", "/v1/templates", fn conn ->
      assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer #{@api_key}"]

      json_resp(conn, 200, %{"templates" => []})
    end)

    assert {:ok, %{"templates" => []}} = Templates.list()
  end

  test "raises without an api key" do
    assert_raise RuntimeError, ~r/Supply a Mailcast API key/, fn ->
      Templates.list(base_url: "http://localhost:9")
    end
  end

  defp parse_json(conn) do
    Plug.Parsers.call(
      conn,
      Plug.Parsers.init(parsers: [:json], json_decoder: Jason)
    )
  end

  defp json_resp(conn, status, body) do
    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.resp(status, Jason.encode!(body))
  end
end
