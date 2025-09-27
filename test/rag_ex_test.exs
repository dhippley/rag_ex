defmodule RagExTest do
  use ExUnit.Case
  doctest RagEx

  test "greets the world" do
    assert RagEx.hello() == :world
  end
end
