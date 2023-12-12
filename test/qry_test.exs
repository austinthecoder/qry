defmodule QryTest do
  use ExUnit.Case
  doctest Qry

  test "greets the world" do
    assert Qry.hello() == :world
  end
end
