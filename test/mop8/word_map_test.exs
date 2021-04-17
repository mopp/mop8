defmodule Mop8.WordMapTest do
  use ExUnit.Case, async: true

  alias Mop8.Ngram
  alias Mop8.WordMap

  test "new/0 creates empty WordMap" do
    assert %{} == WordMap.new()
  end

  describe "put/2" do
    test "does nothing when the empty words is given" do
      word_map = WordMap.new()
      assert word_map == WordMap.put(word_map, [])
    end

    test "stores the given words into the given WordMap" do
      word_map = WordMap.new()

      word_map = WordMap.put(word_map, ["あい", "うえ"])
      assert %{"あい" => %{"うえ" => 1}} == word_map
    end

    test "stores the given words based on Ngram into the given WordMap" do
      word_map = WordMap.new()
      words = Ngram.encode("今日はいい天気ですね。")
      word_map = WordMap.put(word_map, words)

      assert %{
               "今日" => %{"日は" => 1},
               "いい" => %{"い天" => 1},
               "い天" => %{"天気" => 1},
               "すね" => %{"ね。" => 1},
               "です" => %{"すね" => 1},
               "はい" => %{"いい" => 1},
               "天気" => %{"気で" => 1},
               "日は" => %{"はい" => 1},
               "気で" => %{"です" => 1}
             } == word_map

      word_map = WordMap.put(word_map, words)

      assert %{
               "今日" => %{"日は" => 2},
               "いい" => %{"い天" => 2},
               "い天" => %{"天気" => 2},
               "すね" => %{"ね。" => 2},
               "です" => %{"すね" => 2},
               "はい" => %{"いい" => 2},
               "天気" => %{"気で" => 2},
               "日は" => %{"はい" => 2},
               "気で" => %{"です" => 2}
             } == word_map

      word_map = WordMap.put(word_map, ["今日", "日に"])

      assert %{
               "今日" => %{"日は" => 2, "日に" => 1},
               "いい" => %{"い天" => 2},
               "い天" => %{"天気" => 2},
               "すね" => %{"ね。" => 2},
               "です" => %{"すね" => 2},
               "はい" => %{"いい" => 2},
               "天気" => %{"気で" => 2},
               "日は" => %{"はい" => 2},
               "気で" => %{"です" => 2}
             } == word_map
    end
  end

  describe "build_sentence/1" do
    setup do
      :rand.seed(:exrop, {123, 44, 55})

      word_map =
        WordMap.new()
        |> WordMap.put(Ngram.encode("今日はいい天気ですね。"))

      {:ok, %{word_map: word_map}}
    end

    test "generates a sentence based on the given WordMap", %{word_map: word_map} do
      assert {:ok, sentence} = WordMap.build_sentence(word_map)
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

      assert {:ok, sentence} = WordMap.build_sentence(word_map)
      assert "日はいい天気でしたね。" == Ngram.decode(sentence)
    end

    test "returns error when empty WordMap is given" do
      assert {:error, :nothing_to_say} == WordMap.build_sentence(WordMap.new())
    end
  end
end
