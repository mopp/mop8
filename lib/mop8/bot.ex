defmodule Mop8.Bot do
  require Logger
  alias Mop8.Ngram
  alias Mop8.Sentence
  alias Mop8.Tokenizer
  alias Mop8.WordMap
  alias Mop8.Bot.Config

  # TODO: Create module.
  @type message() :: {user_id :: String.t(), text :: String.t(), event_ts :: pos_integer()}

  @spec handle_message(WordMap.t(), message(), Config.t()) ::
          {:ok, {:reply, String.t()} | {:update, WordMap.t()} | :ignore}
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
