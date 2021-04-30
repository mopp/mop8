defmodule Mop8.Bot.MessageTest do
  use ExUnit.Case

  alias Mop8.Bot.Message

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
