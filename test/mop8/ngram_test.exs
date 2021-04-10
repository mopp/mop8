defmodule Mop8.NgramTest do
  use ExUnit.Case
  alias Mop8.Ngram

  test "bigram returns words" do
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
      ] = Ngram.bigram("今日はいい天気ですね。")
    )

    assert(
      [
        "ああ"
      ] = Ngram.bigram("ああ")
    )

    assert(
      [
        "あ"
      ] = Ngram.bigram("あ")
    )

    assert([] = Ngram.bigram(""))
  end
end
