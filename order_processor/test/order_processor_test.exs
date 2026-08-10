defmodule OrderProcessorTest do
  use ExUnit.Case
  doctest OrderProcessor

  test "greets the world" do
    assert OrderProcessor.hello() == :world
  end
end
