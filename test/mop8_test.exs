defmodule Mop8Test do
  use ExUnit.Case
  doctest Mop8

  test "greets the world" do
    assert Mop8.hello() == :world
  end

  test "bigram" do
    assert(
      [
        "今日",
        "日は",
        "はい",
        "いい",
        "い天",
        "天気",
        "気で",
        "です",
        "すね",
        "ね。"
      ] = Mop8.bigram("今日はいい天気ですね。")
    )

    assert(
      [
        "ああ"
      ] = Mop8.bigram("ああ")
    )

    assert(
      [
        "あ"
      ] = Mop8.bigram("あ")
    )

    assert([] = Mop8.bigram(""))
  end

  test "gram map" do
    bigram = Mop8.bigram("今日はいい天気ですね。")

    gram_map = Mop8.update_gram_map(%{}, bigram)

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
      } == gram_map
    )

    gram_map = Mop8.update_gram_map(gram_map, bigram)

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
      } == gram_map
    )

    gram_map = Mop8.update_gram_map(gram_map, ["今日", "日に"])

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
      } == gram_map
    )

    assert(0 == map_size(Mop8.update_gram_map(%{}, [])))
  end
end
