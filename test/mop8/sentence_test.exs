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
end
