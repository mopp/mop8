defmodule Mop8.Bot do
  require Logger

  alias Mop8.Ngram
  alias Mop8.Tokenizer
  alias Mop8.WordMap
  alias Mop8.Bot.Config
  alias Mop8.Bot.Message

  @spec handle_message(WordMap.t(), Message.t(), Config.t()) ::
          {:ok, {:reply, String.t()} | {:update, WordMap.t()} | :ignore}
  def handle_message(word_map, message, %Config{
        target_user_id: target_user_id,
        bot_user_id: bot_user_id
      }) do
    tokens = Tokenizer.tokenize(message.text)

    Logger.info("Tokens: #{inspect(tokens)}")

    cond do
      {:user_id, bot_user_id} == hd(tokens) ->
        # It's mension to the bot. Create reply.
        case WordMap.build_sentence(word_map) do
          {:ok, sentence} ->
            {:ok, {:reply, Ngram.decode(sentence)}}

          {:error, :nothing_to_say} ->
            {:ok, {:reply, "NO DATA"}}
        end

      message.user_id == target_user_id ->
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
