defmodule Mop8.Bot.MessageTest do
  use ExUnit.Case, async: true

  alias Mop8.Bot.Message
  alias Mop8.Bot.Error.InvalidMessageError

  test "new/4 raises InvalidMessageError when invalid parameter is given" do
    assert_raise InvalidMessageError, fn ->
      Message.new(123, "hi", ~U[2021-04-30 22:12:00Z], "test_channel_id")
    end

    assert_raise InvalidMessageError, fn ->
      Message.new("piyo", 123, ~U[2021-04-30 22:12:00Z], "test_channel_id")
    end

    assert_raise InvalidMessageError, fn ->
      Message.new("piyo", "hi", 123, "test_channel_id")
    end

    assert_raise InvalidMessageError, fn ->
      Message.new("piyo", "hi", ~U[2021-04-30 22:12:00Z], 123)
    end
  end

  describe "is_mention?/2" do
    test "returns true when the given message is mention to the given user ID" do
      message =
        Message.new(
          "test_user_id",
          "<@bot_user_id> hi",
          ~U[2021-04-30 22:12:00Z],
          "test_channel_id"
        )

      assert true == Message.is_mention?(message, "bot_user_id")
    end

    test "returns false when the given message is NOT mention to the given user ID" do
      message =
        Message.new(
          "test_user_id",
          "<@bot_user_id> hi",
          ~U[2021-04-30 22:12:00Z],
          "test_channel_id"
        )

      assert false == Message.is_mention?(message, "hoge")
    end
  end

  test "tokenize/1 tokenizes the test in the given message" do
    message = build_message("<@X01X6T8LTAT>うみゃー")

    assert(
      [
        {:user_id, "X01X6T8LTAT"},
        {:text, "うみゃー"}
      ] == Message.tokenize(message)
    )

    message = build_message("てすと<@X01X6T8LTAT>うみゃー")

    assert(
      [
        {:text, "てすと"},
        {:user_id, "X01X6T8LTAT"},
        {:text, "うみゃー"}
      ] == Message.tokenize(message)
    )

    message = build_message("てすと\n```aa\nああ```\nてすと")

    assert(
      [
        {:text, "てすと"},
        {:code, "aa\nああ"},
        {:text, "てすと"}
      ] == Message.tokenize(message)
    )

    message = build_message("これです\n<http://example.com/hoge>")

    assert(
      [
        {:text, "これです"},
        {:uri, "http://example.com/hoge"}
      ] == Message.tokenize(message)
    )

    message = build_message("aa\n&gt; xyz \n&gt; \n&gt; cv\n```a\na```\n*あldskjfはlk*")

    assert(
      [
        {:text, "aa"},
        {:quote, "xyz "},
        {:quote, ""},
        {:quote, "cv"},
        {:code, "a\na"},
        {:bold, "あldskjfはlk"}
      ] == Message.tokenize(message)
    )
  end

  def build_message(text) do
    Message.new("hoge", text, ~U[2021-04-30 22:12:00Z], "test_channel_id")
  end
end
