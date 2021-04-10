defmodule Mop8Test do
  use ExUnit.Case
  alias Mop8.WordMap
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

  test "construct_sentence" do
    :rand.seed(:exrop, {123, 44, 55})

    bigram = Mop8.bigram("今日はいい天気ですね。")

    word_map =
      WordMap.new()
      |> WordMap.put(bigram)

    assert("はいい天気ですね。" == Mop8.construct_sentence(word_map))

    source_sentences = [
      "今日はいい天気でしたね。",
      "明日はいい天気でしたね。",
      "昨日はいい天気でしたよ。"
    ]

    gram_map =
      source_sentences
      |> Enum.map(&Mop8.bigram/1)
      |> Enum.reduce(word_map, &WordMap.put(&2, &1))

    assert("日はいい天気でしたね。" == Mop8.construct_sentence(gram_map))
  end

  test "do_roulette_selection" do
    pairs = [
      {:a, 1},
      {:b, 1},
      {:c, 1}
    ]

    assert(:a == Mop8.do_roulette_selection(pairs, 1))
    assert(:b == Mop8.do_roulette_selection(pairs, 2))
    assert(:c == Mop8.do_roulette_selection(pairs, 3))

    pairs = [
      {:a, 2},
      {:b, 10},
      {:c, 2}
    ]

    assert(:b == Mop8.do_roulette_selection(pairs, 3))
    assert(:b == Mop8.do_roulette_selection(pairs, 12))

    pairs = [
      {:a, 10},
      {:b, 10},
      {:c, 10}
    ]

    assert(:a == Mop8.do_roulette_selection(pairs, 10))
    assert(:b == Mop8.do_roulette_selection(pairs, 19))
  end
end
