defmodule Mop8.NgramTest do
  use ExUnit.Case
  alias Mop8.Ngram

  test "encode divides the given string to n-gram" do
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
      ] = Ngram.encode("今日はいい天気ですね。")
    )

    assert(
      [
        "ああ"
      ] = Ngram.encode("ああ")
    )

    assert(
      [
        "あ"
      ] = Ngram.encode("あ")
    )

    assert([] = Ngram.encode(""))
  end

  test "decode concats the given words to a string" do
    assert(
      "今日はいい天気ですね。" =
        Ngram.decode([
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
        ])
    )
  end
end
