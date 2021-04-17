defmodule Mop8.SelectorTest do
  use ExUnit.Case, async: true

  alias Mop8.Selector

  test "roulette/1 selects value based on roulette selection" do
    pairs = [
      {:a, 1},
      {:b, 1},
      {:c, 1}
    ]

    assert(:a == Selector.roulette(pairs, 1))
    assert(:b == Selector.roulette(pairs, 2))
    assert(:c == Selector.roulette(pairs, 3))

    pairs = [
      {:a, 2},
      {:b, 10},
      {:c, 2}
    ]

    assert(:b == Selector.roulette(pairs, 3))
    assert(:b == Selector.roulette(pairs, 12))

    pairs = [
      {:a, 10},
      {:b, 10},
      {:c, 10}
    ]

    assert(:a == Selector.roulette(pairs, 10))
    assert(:b == Selector.roulette(pairs, 19))
  end
end
