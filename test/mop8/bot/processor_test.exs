defmodule Mop8.Bot.ProcessorTest do
  use ExUnit.Case, async: true

  alias Mop8.Adapter.MessageStore
  alias Mop8.Adapter.WordMapStore
  alias Mop8.Bot.Config
  alias Mop8.Bot.Message
  alias Mop8.Bot.Processor
  alias Mop8.Bot.WordMap
  alias Support.TestReplyer

  describe "process_message/2" do
    @describetag :tmp_dir

    setup %{tmp_dir: tmp_dir} do
      :rand.seed(:exrop, {321, 88, 67})

      test_replyer = TestReplyer.new()

      processor =
        Processor.new(
          Config.new(
            "test_target_user_id",
            "test_bot_id"
          ),
          WordMapStore.new(
            [tmp_dir, "word_map.json"]
            |> Path.join()
            |> Path.expand()
          ),
          MessageStore.new(
            [tmp_dir, "messages.json"]
            |> Path.join()
            |> Path.expand()
          ),
          test_replyer
        )

      {:ok, processor: processor, test_replyer: test_replyer}
    end

    test "creates empty reply when it receives mention and the WordMap is empty", %{
      processor: processor,
      test_replyer: test_replyer
    } do
      message =
        Message.new("hoge", "<@test_bot_id> hi", ~U[2021-04-30 22:12:00Z], "test_channel_id")

      Processor.process_message(processor, message)

      assert ["NO DATA"] = TestReplyer.get_replies(test_replyer)
    end

    test "creates reply when it receives mention", %{
      processor: processor,
      test_replyer: test_replyer
    } do
      message =
        Message.new(
          "test_target_user_id",
          "<@test_bot_id> hi",
          ~U[2021-04-30 22:12:00Z],
          "test_channel_id"
        )

      Processor.process_message(processor, message)

      assert ["hi"] = TestReplyer.get_replies(test_replyer)
    end
  end

  test "put_message/2 stores the given Message into the given WordMap" do
    message = Message.new("test_user_id", "hi", ~U[2021-04-19 22:12:00Z], "test_channel_id")
    word_map = WordMap.new()

    assert %{"hi" => %{count: 1, heads: 1, nexts: [], tails: 1}} ==
             Processor.put_message(message, word_map)
  end
end
