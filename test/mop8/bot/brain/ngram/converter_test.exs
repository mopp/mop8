defmodule Mop8.Bot.Brain.Ngram.ConverterTest do
  use ExUnit.Case, async: true

  alias Mop8.Bot.Brain.Ngram.Converter

  test "encode/1 divides the given string to N-gram (default N = 2)" do
    assert [] == Converter.encode("")

    assert ["あ"] == Converter.encode("あ")

    assert ["ああ"] == Converter.encode("ああ")

    assert ["あい", "いう"] == Converter.encode("あいう")

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
           ] == Converter.encode("今日はいい天気ですね。")
  end

  test "decode/1 concats the given N-gram to a string (default N = 2)" do
    assert "" == Converter.decode([])

    assert "あい" == Converter.decode(["あい"])

    assert "今日はいい天気ですね。" ==
             Converter.decode([
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
    assert ["abc"] == Converter.encode("abc", 3)

    assert ["abc", "bcd"] == Converter.encode("abcd", 3)

    assert ["aaabbbcccd", "aabbbcccde"] == Converter.encode("aaabbbcccde", 10)
  end

  test "decode/1 concats the given N-gram to a string (N is given)" do
    assert "abc" == Converter.decode(["abc"], 3)

    assert "abcd" == Converter.decode(["abc", "bcd"], 3)

    assert "aaabbbcccde" == Converter.decode(["aaabbbcccd", "aabbbcccde"], 10)
  end
end
