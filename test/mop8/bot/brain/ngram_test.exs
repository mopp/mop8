defmodule Mop8.Bot.Brain.NgramTest do
  use ExUnit.Case, async: true

  alias Mop8.Adapter.WordMapStore
  alias Mop8.Bot.Brain
  alias Mop8.Bot.Brain.Ngram
  alias Mop8.Bot.Message

  describe "NgramBrain" do
    @describetag :tmp_dir

    setup %{tmp_dir: tmp_dir} do
      start_supervised!(
        {Ngram,
         %{
           word_map_store:
             WordMapStore.new(
               [tmp_dir, "word_map.json"]
               |> Path.join()
               |> Path.expand()
             ),
           seed: {321, 88, 67}
         }}
      )

      :ok
    end

    test "normal cases" do
      message1 = Message.new("<@test_bot_id> hi", ~U[2021-04-30 22:12:00Z])
      message2 = Message.new("あああ", ~U[2021-04-30 22:12:30Z])
      assert :ok == Brain.learn(message1)
      assert :ok == Brain.learn(message2)

      assert {:ok, "あああ"} == Brain.reply({})

      message1 = Message.new("<@test_bot_id> yo", ~U[2021-04-30 22:12:00Z])
      message2 = Message.new("ううう", ~U[2021-04-30 22:12:30Z])
      assert :ok == Brain.relearn([message1, message2])

      assert {:ok, "うう"} == Brain.reply({})
    end
  end
end
