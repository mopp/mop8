defmodule Mop8.WordMapStoreTest do
  use ExUnit.Case

  alias Mop8.WordMap
  alias Mop8.WordMapStore
  alias Mop8.Repo
  alias Mop8.Ngram

  describe "load/1 and store/2" do
    setup do
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

    @tag :tmp_dir
    test "writes the WordMap into the file and reads the WordMap from the given file", %{
      tmp_dir: tmp_dir,
      word_map: word_map
    } do
      System.put_env("MOP8_STORAGE_DIR", tmp_dir)

      store = WordMapStore.new()
      assert {:ok, store} == Repo.WordMap.store(store, word_map)
      assert {:ok, {store, word_map}} == Repo.WordMap.load(store)
    end
  end
end
