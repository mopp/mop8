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
end
