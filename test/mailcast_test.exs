defmodule MailcastTest do
  use ExUnit.Case
  doctest Mailcast

  test "greets the world" do
    assert Mailcast.hello() == :world
  end
end
