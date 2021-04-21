defmodule Mop8.BotTest do
  use ExUnit.Case, async: true

  alias Mop8.Bot
  alias Mop8.Bot.Message
  alias Mop8.Bot.WordMap

  test "handle_message/3" do
    word_map = WordMap.new()
    config = Bot.Config.new("test_user_id", "test_bot_user_id")

    message = Message.new("other_user_id", "hi", ~U[2021-04-18 23:21:27Z])
    assert {:ok, :ignore} == Bot.handle_message(word_map, message, config)

    message = Message.new("test_user_id", "hi", ~U[2021-04-18 23:21:27Z])
    assert {:ok, {:update, _}} = Bot.handle_message(word_map, message, config)

    message =
      Message.new(
        "test_user_id",
        "hi with <http://example.com/hoge>",
        ~U[2021-04-18 23:21:27Z]
      )

    assert {:ok, {:update, _}} = Bot.handle_message(word_map, message, config)

    message = Message.new("target_user_id", "<@test_bot_user_id> hi", ~U[2021-04-18 23:21:27Z])

    assert {:ok, {:reply, "NO DATA"}} == Bot.handle_message(word_map, message, config)

    word_map = WordMap.put(word_map, ["あい", "うえ"])

    message = Message.new("target_user_id", "<@test_bot_user_id> hi", ~U[2021-04-18 23:21:27Z])

    assert {:ok, {:reply, _}} = Bot.handle_message(word_map, message, config)
  end

  test "rebuild_word_map/2" do
    config = Bot.Config.new("test_user_id", "test_bot_user_id")

    messages = [
      Message.new("test_user_id", "hi", ~U[2021-04-18 23:21:27Z]),
      Message.new("user_id", "hi", ~U[2021-04-19 00:11:00Z]),
      Message.new("user_id", "<@test_bot_user_id> hi", ~U[2021-04-19 00:11:00Z]),
      Message.new("test_user_id", "hi", ~U[2021-04-19 00:11:00Z]),
      Message.new("test_user_id", "yo", ~U[2021-04-19 00:13:00Z])
    ]

    assert %{
             "hi" => %{count: 2, next_map: %{}},
             "yo" => %{count: 1, next_map: %{}}
           } == Bot.rebuild_word_map(messages, config)
  end
end
