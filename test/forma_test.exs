defmodule FormaTest do
  use ExUnit.Case
  doctest Forma

  test "greets the world" do
    assert Forma.hello() == :world
  end
end
