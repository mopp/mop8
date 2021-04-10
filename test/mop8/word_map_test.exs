defmodule Mop8.WordMapTest do
  use ExUnit.Case
  alias Mop8.WordMap

  test "new" do
    assert(%{} == WordMap.new())
  end

  test "put" do
    word_map = WordMap.new()
    assert(%{} == WordMap.put(word_map, []))

    bigram = Mop8.bigram("今日はいい天気ですね。")
    word_map = WordMap.put(word_map, bigram)

    assert(
      %{
        "今日" => %{"日は" => 1},
        "いい" => %{"い天" => 1},
        "い天" => %{"天気" => 1},
        "すね" => %{"ね。" => 1},
        "です" => %{"すね" => 1},
        "はい" => %{"いい" => 1},
        "天気" => %{"気で" => 1},
        "日は" => %{"はい" => 1},
        "気で" => %{"です" => 1}
      } == word_map
    )

    word_map = WordMap.put(word_map, bigram)

    assert(
      %{
        "今日" => %{"日は" => 2},
        "いい" => %{"い天" => 2},
        "い天" => %{"天気" => 2},
        "すね" => %{"ね。" => 2},
        "です" => %{"すね" => 2},
        "はい" => %{"いい" => 2},
        "天気" => %{"気で" => 2},
        "日は" => %{"はい" => 2},
        "気で" => %{"です" => 2}
      } == word_map
    )

    word_map = WordMap.put(word_map, ["今日", "日に"])

    assert(
      %{
        "今日" => %{"日は" => 2, "日に" => 1},
        "いい" => %{"い天" => 2},
        "い天" => %{"天気" => 2},
        "すね" => %{"ね。" => 2},
        "です" => %{"すね" => 2},
        "はい" => %{"いい" => 2},
        "天気" => %{"気で" => 2},
        "日は" => %{"はい" => 2},
        "気で" => %{"です" => 2}
      } == word_map
    )
  end
end
