defmodule Mop8.NgramTest do
  use ExUnit.Case, async: true

  alias Mop8.Ngram

  test "encode/1 divides the given string to n-gram (default N = 2)" do
    assert [] == Ngram.encode("")

    assert ["あ"] == Ngram.encode("あ")

    assert ["ああ"] == Ngram.encode("ああ")

    assert [
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
           ] == Ngram.encode("今日はいい天気ですね。")
  end

  test "decode/1 concats the given words to a string" do
    assert "" == Ngram.decode([])

    assert "あい" == Ngram.decode(["あい"])

    assert "今日はいい天気ですね。" ==
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
  end
end
