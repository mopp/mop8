defmodule Mop8.Bot.Processor do
  require Logger

  alias Mop8.Bot.Config
  alias Mop8.Bot.Message
  alias Mop8.Bot.Ngram
  alias Mop8.Bot.Repo
  alias Mop8.Bot.Tokenizer
  alias Mop8.Bot.WordMap

  defstruct [
    :config,
    :word_map_store,
    :message_store
  ]

  @type t :: %__MODULE__{
          config: Config.t(),
          word_map_store: Repo.WordMap.t(),
          message_store: Repo.Message.t()
        }

  @spec new(Config.t(), Repo.WordMap.t(), Repo.Message.t()) :: t()
  def new(config, word_map_store, message_store) do
    %__MODULE__{
      config: config,
      word_map_store: word_map_store,
      message_store: message_store
    }
  end

  @spec process_message(t(), Message.t()) :: t()
  def process_message(processor, message) do
    tokens = Tokenizer.tokenize(message.text)

    %__MODULE__{
      config: config,
      word_map_store: word_map_store,
      message_store: message_store
    } = processor

    cond do
      {:user_id, config.bot_user_id} == hd(tokens) ->
        # It's mension to the bot. Create reply.

        {:ok, {word_map_store, word_map}} = Repo.WordMap.load(word_map_store)

        sentence =
          case WordMap.build_sentence(word_map) do
            {:ok, sentence} ->
              Ngram.decode(sentence)

            {:error, :nothing_to_say} ->
              "NO DATA"
          end

        Logger.info("Reply: #{sentence}")

        # TODO: fetch target channel from the message.
        target_channel_id = System.fetch_env!("TARGET_CHANNEL_ID")

        # TODO: Define interface and separate the implementation.
        response = Slack.Web.Chat.post_message(target_channel_id, sentence)
        Logger.info("Response: #{inspect(response)}")

        %{processor | word_map_store: word_map_store}

      message.user_id == config.target_user_id ->
        # Store the target user message.
        {:ok, {message_store, _messages}} = Repo.Message.all(message_store)
        {:ok, message_store} = Repo.Message.insert(message_store, message)

        Logger.info("Tokens: #{inspect(tokens)}")

        {:ok, {word_map_store, word_map}} = Repo.WordMap.load(word_map_store)

        Enum.reduce(tokens, word_map, fn
          {:text, text}, acc ->
            words = Ngram.encode(text)
            WordMap.put(acc, words)

          _, acc ->
            acc
        end)

        {:ok, word_map_store} = Repo.WordMap.store(word_map_store, word_map)

        %{processor | message_store: message_store, word_map_store: word_map_store}

      true ->
        # Ignore

        processor
    end
  end
end
