defmodule Mop8.BotTest do
  use ExUnit.Case, async: true

  alias Mop8.WordMap
  alias Mop8.Bot

  test 'handle_message/3' do
    word_map = WordMap.new()
    config = Bot.Config.new("test_user_id", "test_bot_user_id")

    message = {"other_user_id", "hi", 123}
    assert {:ok, :ignore} == Bot.handle_message(word_map, message, config)

    message = {"test_user_id", "hi", 123}
    assert {:ok, {:update, _}} = Bot.handle_message(word_map, message, config)

    message = {"test_user_id", "hi with <http://example.com/hoge>", 123}
    assert {:ok, {:update, _}} = Bot.handle_message(word_map, message, config)

    message = {"target_user_id", "<@test_bot_user_id> hi", 123}
    assert {:ok, {:reply, "NO DATA"}} == Bot.handle_message(word_map, message, config)

    word_map = WordMap.put(word_map, ["あい", "うえ"])
    message = {"target_user_id", "<@test_bot_user_id> hi", 123}
    assert {:ok, {:reply, _}} = Bot.handle_message(word_map, message, config)
  end
end
