defmodule Mop8.Bot.NgramTest do
  use ExUnit.Case, async: true

  alias Mop8.Bot.Ngram

  test "encode/1 divides the given string to N-gram (default N = 2)" do
    assert [] == Ngram.encode("")

    assert ["あ"] == Ngram.encode("あ")

    assert ["ああ"] == Ngram.encode("ああ")

    assert ["あい", "いう"] == Ngram.encode("あいう")

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

  test "decode/1 concats the given N-gram to a string (default N = 2)" do
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

  test "encode/1 divides the given string to N-gram (N is given)" do
    assert ["abc"] == Ngram.encode("abc", 3)

    assert ["abc", "bcd"] == Ngram.encode("abcd", 3)

    assert ["aaabbbcccd", "aabbbcccde"] == Ngram.encode("aaabbbcccde", 10)
  end

  test "decode/1 concats the given N-gram to a string (N is given)" do
    assert "abc" == Ngram.decode(["abc"], 3)

    assert "abcd" == Ngram.decode(["abc", "bcd"], 3)

    assert "aaabbbcccde" == Ngram.decode(["aaabbbcccd", "aabbbcccde"], 10)
  end
end
