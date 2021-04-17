defmodule Mop8.SentenceTest do
  use ExUnit.Case, async: true

  alias Mop8.Ngram
  alias Mop8.Sentence
  alias Mop8.WordMap

  setup do
    :rand.seed(:exrop, {123, 44, 55})

    word_map =
      WordMap.new()
      |> WordMap.put(Ngram.encode("今日はいい天気ですね。"))

    {:ok, %{word_map: word_map}}
  end

  test "construct/1 generates a sentence based on the given WordMap", %{word_map: word_map} do
    assert {:ok, sentence} = Sentence.construct(word_map)
    assert "はいい天気ですね。" == Ngram.decode(sentence)

    source_sentences = [
      "今日はいい天気でしたね。",
      "明日はいい天気でしたね。",
      "昨日はいい天気でしたよ。"
    ]

    word_map =
      source_sentences
      |> Enum.map(&Ngram.encode/1)
      |> Enum.reduce(word_map, &WordMap.put(&2, &1))

    assert {:ok, sentence} = Sentence.construct(word_map)
    assert "日はいい天気でしたね。" == Ngram.decode(sentence)
  end

  test "construct/1 returns error when empty WordMap is given" do
    assert {:error, :nothing_to_say} == Sentence.construct(WordMap.new())
  end
end
