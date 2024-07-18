defmodule NewtTest do
  use ExUnit.Case
  doctest Newt

  test "greets the world" do
    assert Newt.hello() == :world
  end
end
