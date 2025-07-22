defmodule Mailcast.WebhooksTest do
  use ExUnit.Case

  @test_secret "phtfyRaeEm2ykUAYm6XtJoIFiinDmL8g1OHPBA"

  @test_body ~s({"data":{"click_tracking":false,"email_id":"email_01k0rpevqcfkg9z4vpgfct5pdm","from":"from@example.com","open_tracking":false,"recipients":["to@example.com"],"subject":"Test","tags":[],"transactional":false},"domain":"example.com","event":"email.sent","timestamp":"2025-07-22T09:11:59Z"})
  @test_signature "B0QZy14FqS21Y6Ie3Jasc4YjZmNCcxXeGpDyXTnHUD8="
  @test_timestamp "2025-07-22T09:11:59Z"

  setup do
    Application.put_env(:mailcast, :webhook_secret, @test_secret)

    on_exit(fn ->
      Application.delete_env(:mailcast, :webhook_secret)
    end)

    :ok
  end

  test "verify_signature/3 without raw body" do
    conn = %Plug.Conn{}

    assert_raise RuntimeError, ~r/Cannot verify signature without the raw body/, fn ->
      Mailcast.Webhooks.verify_signature(conn)
    end
  end

  test "verify_signature/3 with raw body" do
    conn =
      %Plug.Conn{
        assigns: %{raw_body: @test_body}
      }
      |> Plug.Conn.put_req_header("x-mailcast-timestamp", @test_timestamp)
      |> Plug.Conn.put_req_header("x-mailcast-signature", @test_signature)

    assert Mailcast.Webhooks.verify_signature(conn) == :ok
  end

  test "verify_signature/3 with supplied raw body" do
    conn =
      %Plug.Conn{}
      |> Plug.Conn.put_req_header("x-mailcast-timestamp", @test_timestamp)
      |> Plug.Conn.put_req_header("x-mailcast-signature", @test_signature)

    assert Mailcast.Webhooks.verify_signature(conn, @test_body) == :ok
  end

  test "verify_signature/3 with missing header" do
    conn =
      %Plug.Conn{
        assigns: %{raw_body: @test_body}
      }
      |> Plug.Conn.put_req_header("x-mailcast-timestamp", @test_timestamp)

    assert Mailcast.Webhooks.verify_signature(conn) == {:error, "Missing header"}
  end

  test "verify_signature/3 with invalid signature" do
    conn =
      %Plug.Conn{
        assigns: %{raw_body: @test_body}
      }
      |> Plug.Conn.put_req_header("x-mailcast-timestamp", @test_timestamp)
      |> Plug.Conn.put_req_header("x-mailcast-signature", "invalid")

    assert Mailcast.Webhooks.verify_signature(conn) == {:error, "Invalid signature"}
  end
end
