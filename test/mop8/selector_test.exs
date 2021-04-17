defmodule Mop8.SelectorTest do
  use ExUnit.Case, async: true

  alias Mop8.Selector

  test "roulette/1 selects value based on roulette selection" do
    elements = [
      {:a, 1},
      {:b, 1},
      {:c, 1}
    ]

    assert {:ok, :a} == Selector.roulette(elements, fn _ -> 1 end)
    assert {:ok, :b} == Selector.roulette(elements, fn _ -> 2 end)
    assert {:ok, :c} == Selector.roulette(elements, fn _ -> 3 end)

    elements = [
      {:a, 2},
      {:b, 10},
      {:c, 2}
    ]

    assert {:ok, :a} == Selector.roulette(elements, fn _ -> 2 end)
    assert {:ok, :b} == Selector.roulette(elements, fn _ -> 3 end)
    assert {:ok, :b} == Selector.roulette(elements, fn _ -> 12 end)
    assert {:ok, :c} == Selector.roulette(elements, fn _ -> 13 end)
  end

  test "roulette/1 returns error when empty list is given" do
    assert {:error, :no_element} == Selector.roulette([])
  end

  test "roulette/1 raises error when random number generator returns invalid value" do
    elements = [
      {:a, 1},
      {:b, 1},
      {:c, 1}
    ]

    assert_raise RuntimeError, fn ->
      Selector.roulette(elements, fn _ -> 4 end)
    end
  end
end
