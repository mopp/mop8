defmodule Mop8.SentenceTest do
  use ExUnit.Case
  alias Mop8.Ngram
  alias Mop8.Sentence
  alias Mop8.WordMap

  test "constructs a sentence based on the given WordMap" do
    :rand.seed(:exrop, {123, 44, 55})

    bigram = Ngram.encode("今日はいい天気ですね。")

    word_map =
      WordMap.new()
      |> WordMap.put(bigram)

    assert("はいい天気ですね。" == Sentence.construct(word_map) |> Ngram.decode())

    source_sentences = [
      "今日はいい天気でしたね。",
      "明日はいい天気でしたね。",
      "昨日はいい天気でしたよ。"
    ]

    word_map =
      source_sentences
      |> Enum.map(&Ngram.encode/1)
      |> Enum.reduce(word_map, &WordMap.put(&2, &1))

    assert("日はいい天気でしたね。" == Sentence.construct(word_map) |> Ngram.decode())
  end

  test "do_roulette_selection" do
    pairs = [
      {:a, 1},
      {:b, 1},
      {:c, 1}
    ]

    assert(:a == Sentence.do_roulette_selection(pairs, 1))
    assert(:b == Sentence.do_roulette_selection(pairs, 2))
    assert(:c == Sentence.do_roulette_selection(pairs, 3))

    pairs = [
      {:a, 2},
      {:b, 10},
      {:c, 2}
    ]

    assert(:b == Sentence.do_roulette_selection(pairs, 3))
    assert(:b == Sentence.do_roulette_selection(pairs, 12))

    pairs = [
      {:a, 10},
      {:b, 10},
      {:c, 10}
    ]

    assert(:a == Sentence.do_roulette_selection(pairs, 10))
    assert(:b == Sentence.do_roulette_selection(pairs, 19))
  end
end
