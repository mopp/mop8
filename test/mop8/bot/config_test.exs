defmodule Mop8.Bot.ConfigTest do
  use ExUnit.Case, async: true

  alias Mop8.Bot.Config
  alias Mop8.Bot.Error.ConfigError

  test "new/2 creates Bot.Config successfully" do
    assert %Config{
             target_user_id: "test_target_user_id",
             bot_user_id: "test_bot_user_id"
           } == Config.new("test_target_user_id", "test_bot_user_id")
  end

  test "new/2 raises ConfigError when invalid parameters are given" do
    assert_raise ConfigError,
                 fn ->
                   Config.new(123, "test_bot_user_id")
                 end

    assert_raise ConfigError,
                 fn ->
                   Config.new("", "test_bot_user_id")
                 end

    assert_raise ConfigError,
                 fn ->
                   Config.new("test_target_user_id", 123)
                 end

    assert_raise ConfigError,
                 fn ->
                   Config.new("test_target_user_id", "")
                 end
  end
end
