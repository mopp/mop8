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

    message =
      build_message(
        "クリーンアーキテクチャ本のメモを読み直してる\n<https://scrapbox.io/mopp/Clean_Architecture_%E9%81%94%E4%BA%BA%E3%81%AB%E5%AD%A6%E3%81%B6%E3%82%BD%E3%83%95%E3%83%88%E3%82%A6%E3%82%A7%E3%82%A2%E3%81%AE%E6%A7%8B%E9%80%A0%E3%81%A8%E8%A8%AD%E8%A8%88|https://scrapbox.io/mopp/Clean_Architecture_%E9%81%94%E4%BA%BA%E3%81%AB%E5%AD%A6%E[…]%E3%82%A2%E3%81%AE%E6%A7%8B%E9%80%A0%E3%81%A8%E8%A8%AD%E8%A8%88>"
      )

    assert(
      [
        {:text, "クリーンアーキテクチャ本のメモを読み直してる"},
        {:uri,
         "https://scrapbox.io/mopp/Clean_Architecture_%E9%81%94%E4%BA%BA%E3%81%AB%E5%AD%A6%E3%81%B6%E3%82%BD%E3%83%95%E3%83%88%E3%82%A6%E3%82%A7%E3%82%A2%E3%81%AE%E6%A7%8B%E9%80%A0%E3%81%A8%E8%A8%AD%E8%A8%88|https://scrapbox.io/mopp/Clean_Architecture_%E9%81%94%E4%BA%BA%E3%81%AB%E5%AD%A6%E[…]%E3%82%A2%E3%81%AE%E6%A7%8B%E9%80%A0%E3%81%A8%E8%A8%AD%E8%A8%88"}
      ] == Message.tokenize(message)
    )
  end

  def build_message(text) do
    Message.new("hoge", text, ~U[2021-04-30 22:12:00Z], "test_channel_id")
  end
end
