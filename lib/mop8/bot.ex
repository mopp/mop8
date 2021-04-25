defmodule Mop8.Bot do
  require Logger

  alias Mop8.Bot.Config
  alias Mop8.Bot.Message
  alias Mop8.Bot.Ngram
  alias Mop8.Bot.WordMap
  alias Mop8.Bot.Tokenizer

  @spec handle_message(WordMap.t(), Message.t(), Config.t()) ::
          {:ok, {:reply, String.t()} | {:update, WordMap.t()} | :ignore}
  def handle_message(word_map, message, config) do
    case decide_action(message, config) do
      :reply ->
        case WordMap.build_sentence(word_map) do
          {:ok, sentence} ->
            {:ok, {:reply, Ngram.decode(sentence)}}

          {:error, :nothing_to_say} ->
            {:ok, {:reply, "NO DATA"}}
        end

      {:store, tokens} ->
        {:ok, {:update, put_tokens(word_map, tokens)}}

      :ignore ->
        {:ok, :ignore}
    end
  end

  @spec rebuild_word_map([Message.t()], Config.t()) :: WordMap.t()
  def rebuild_word_map(messages, config) do
    Enum.reduce(messages, WordMap.new(), fn message, acc ->
      case decide_action(message, config) do
        :reply ->
          acc

        {:store, tokens} ->
          put_tokens(acc, tokens)

        :ignore ->
          acc
      end
    end)
  end

  defp decide_action(message, %Config{target_user_id: target_user_id, bot_user_id: bot_user_id}) do
    tokens = Tokenizer.tokenize(message.text)

    Logger.info("Tokens: #{inspect(tokens)}")

    cond do
      {:user_id, bot_user_id} == hd(tokens) ->
        # It's mension to the bot. Create reply.
        :reply

      message.user_id == target_user_id ->
        # Store the target user message.
        {:store, tokens}

      true ->
        :ignore
    end
  end

  defp put_tokens(word_map, tokens) do
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
  end
end
