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
        {:text, "てすと\n"},
        {:code, "aa\nああ"},
        {:text, "\nてすと"}
      ] == Tokenizer.tokenize("てすと\n```aa\nああ```\nてすと")
    )

    assert(
      [
        {:text, "これです\n"},
        {:uri, "http://example.com/hoge"}
      ] == Tokenizer.tokenize("これです\n<http://example.com/hoge>")
    )

    assert(
      [
        {:text, "aa\n"},
        {:quote, "xyz "},
        {:quote, ""},
        {:quote, "cv"},
        {:code, "a\na"},
        {:text, "\n"},
        {:bold, "あldskjfはlk"}
      ] == Tokenizer.tokenize("aa\n&gt; xyz \n&gt; \n&gt; cv\n```a\na```\n*あldskjfはlk*")
    )
  end
end
