defmodule LiveQueryTest do
  use ExUnit.Case
  doctest LiveQuery

  test "greets the world" do
    assert LiveQuery.hello() == :world
  end
end
