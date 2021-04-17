defmodule Mop8.Bot do
  require Logger
  alias Mop8.Ngram
  alias Mop8.Sentence
  alias Mop8.Tokenizer
  alias Mop8.WordMap
  alias Mop8.Bot.Config

  def handle_message(
        word_map,
        {user_id, text, _event_ts},
        %Config{
          target_user_id: target_user_id,
          bot_user_id: bot_user_id
        }
      ) do
    tokens = Tokenizer.tokenize(text)

    cond do
      {:user_id, bot_user_id} == hd(tokens) ->
        # It's mension to the bot. Create reply.
        sentence =
          word_map
          |> Sentence.construct()
          |> Ngram.decode()

        {:ok, {:reply, sentence}}

      user_id == target_user_id ->
        # Store the target user words.
        word_map =
          Enum.reduce(
            tokens,
            word_map,
            fn
              {:text, text}, acc ->
                words = Ngram.encode(text)
                WordMap.put(acc, words)

              _, acc ->
                acc
            end
          )

        {:ok, {:update, word_map}}

      true ->
        # Ignore
        {:ok, :ignore}
    end
  end
end
