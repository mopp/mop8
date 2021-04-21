defmodule Mop8.WordMapTest do
  use ExUnit.Case, async: true

  alias Mop8.Bot.Ngram
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

      assert %{
               "あい" => %{count: 1, next_map: %{"うえ" => 1}},
               "うえ" => %{count: 1, next_map: %{}}
             } == word_map

      word_map = WordMap.put(word_map, ["あい", "ab"])

      assert %{
               "あい" => %{count: 2, next_map: %{"うえ" => 1, "ab" => 1}},
               "うえ" => %{count: 1, next_map: %{}},
               "ab" => %{count: 1, next_map: %{}}
             } == word_map

      word_map = WordMap.put(word_map, ["あい"])

      assert %{
               "あい" => %{count: 3, next_map: %{"うえ" => 1, "ab" => 1}},
               "うえ" => %{count: 1, next_map: %{}},
               "ab" => %{count: 1, next_map: %{}}
             } == word_map

      word_map = WordMap.put(word_map, ["xy"])

      assert %{
               "あい" => %{count: 3, next_map: %{"うえ" => 1, "ab" => 1}},
               "うえ" => %{count: 1, next_map: %{}},
               "ab" => %{count: 1, next_map: %{}},
               "xy" => %{count: 1, next_map: %{}}
             } == word_map

      word_map = WordMap.put(word_map, ["あい", "うえ"])

      assert %{
               "あい" => %{count: 4, next_map: %{"うえ" => 2, "ab" => 1}},
               "うえ" => %{count: 2, next_map: %{}},
               "ab" => %{count: 1, next_map: %{}},
               "xy" => %{count: 1, next_map: %{}}
             } == word_map

      word_map = WordMap.put(word_map, ["ab", "うえ"])

      assert %{
               "あい" => %{count: 4, next_map: %{"うえ" => 2, "ab" => 1}},
               "うえ" => %{count: 3, next_map: %{}},
               "ab" => %{count: 2, next_map: %{"うえ" => 1}},
               "xy" => %{count: 1, next_map: %{}}
             } == word_map
    end
  end

  describe "build_sentence/1" do
    setup do
      :rand.seed(:exrop, {123, 44, 55})

      source_sentences = [
        "今日はいい天気でしたね。",
        "明日はいい天気でしたね。",
        "昨日はいい天気でしたよ。"
      ]

      word_map =
        source_sentences
        |> Enum.map(&Ngram.encode/1)
        |> Enum.reduce(WordMap.new(), &WordMap.put(&2, &1))

      {:ok, %{word_map: word_map}}
    end

    test "generates a sentence based on the given WordMap", %{word_map: word_map} do
      {:ok, pid} = Agent.start_link(fn -> nil end)

      test_selector = fn _ ->
        Agent.get_and_update(pid, fn [head | rest] -> {head, rest} end)
      end

      # Set test pattern.
      Agent.cast(pid, fn _ ->
        [
          {:ok, "よ。"},
          {:error, :no_element}
        ]
      end)

      assert {:ok, sentence} = WordMap.build_sentence(word_map, test_selector)
      assert "よ。" == Ngram.decode(sentence)

      # Set test pattern.
      Agent.cast(pid, fn _ ->
        [
          {:ok, "たよ"},
          {:ok, "よ。"},
          {:error, :no_element}
        ]
      end)

      assert {:ok, sentence} = WordMap.build_sentence(word_map, test_selector)
      assert "たよ。" == Ngram.decode(sentence)

      Agent.stop(pid)
    end

    test "returns error when empty WordMap is given" do
      assert {:error, :nothing_to_say} == WordMap.build_sentence(WordMap.new())
    end
  end
end
