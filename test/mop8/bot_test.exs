defmodule Mop8.BotTest do
  use ExUnit.Case, async: true

  alias Mop8.WordMap
  alias Mop8.Bot

  test 'handle_message/3' do
    word_map = WordMap.new()
    config = Bot.Config.new("test_user_id", "test_bot_user_id")

    message = Bot.Message.new("other_user_id", "hi", ~U[2021-04-18 23:21:27Z])
    assert {:ok, :ignore} == Bot.handle_message(word_map, message, config)

    message = Bot.Message.new("test_user_id", "hi", ~U[2021-04-18 23:21:27Z])
    assert {:ok, {:update, _}} = Bot.handle_message(word_map, message, config)

    message =
      Bot.Message.new(
        "test_user_id",
        "hi with <http://example.com/hoge>",
        ~U[2021-04-18 23:21:27Z]
      )

    assert {:ok, {:update, _}} = Bot.handle_message(word_map, message, config)

    message =
      Bot.Message.new("target_user_id", "<@test_bot_user_id> hi", ~U[2021-04-18 23:21:27Z])

    assert {:ok, {:reply, "NO DATA"}} == Bot.handle_message(word_map, message, config)

    word_map = WordMap.put(word_map, ["あい", "うえ"])

    message =
      Bot.Message.new("target_user_id", "<@test_bot_user_id> hi", ~U[2021-04-18 23:21:27Z])

    assert {:ok, {:reply, _}} = Bot.handle_message(word_map, message, config)
  end
end
