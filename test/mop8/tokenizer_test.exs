defmodule Mop8.TokenizerTest do
  use ExUnit.Case

  alias Mop8.Tokenizer

  test "tokenize" do
    assert(
      [
        {:user_id, "X01X6T8LTAT"},
        {:text, "うみゃー"}
      ] == Tokenizer.tokenize("<@X01X6T8LTAT>うみゃー")
    )

    assert(
      [
        {:text, "てすと"},
        {:user_id, "X01X6T8LTAT"},
        {:text, "うみゃー"}
      ] == Tokenizer.tokenize("てすと<@X01X6T8LTAT>うみゃー")
    )

    assert(
      [
        {:text, "てすと"},
        {:code, "aa\nああ"},
        {:text, "てすと"}
      ] == Tokenizer.tokenize("てすと\n```aa\nああ```\nてすと")
    )

    assert(
      [
        {:text, "これです"},
        {:uri, "http://example.com/hoge"}
      ] == Tokenizer.tokenize("これです\n<http://example.com/hoge>")
    )

    assert(
      [
        {:text, "aa"},
        {:quote, "xyz "},
        {:quote, ""},
        {:quote, "cv"},
        {:code, "a\na"},
        {:bold, "あldskjfはlk"}
      ] == Tokenizer.tokenize("aa\n&gt; xyz \n&gt; \n&gt; cv\n```a\na```\n*あldskjfはlk*")
    )
  end
end
