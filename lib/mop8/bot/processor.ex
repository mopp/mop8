defmodule Mop8.Bot.Processor do
  require Logger

  alias Mop8.Bot.Config
  alias Mop8.Bot.Message
  alias Mop8.Bot.Ngram
  alias Mop8.Bot.Replyer
  alias Mop8.Bot.Repo
  alias Mop8.Bot.WordMap

  defstruct [
    :config,
    :word_map_store,
    :message_store,
    :replyer
  ]

  @type t :: %__MODULE__{
          config: Config.t(),
          word_map_store: Repo.WordMap.t(),
          message_store: Repo.Message.t(),
          replyer: Replyer.t()
        }

  @spec new(Config.t(), Repo.WordMap.t(), Repo.Message.t(), Replyer.t()) :: t()
  def new(config, word_map_store, message_store, replyer) do
    {:ok, {message_store, _messages}} = Repo.Message.all(message_store)

    %__MODULE__{
      config: config,
      word_map_store: word_map_store,
      message_store: message_store,
      replyer: replyer
    }
  end

  @spec process_message(t(), Message.t(), String.t(), String.t()) :: t()
  def process_message(processor, message, user_id, channel_id) do
    %__MODULE__{
      config: config,
      word_map_store: word_map_store,
      message_store: message_store,
      replyer: replyer
    } = processor

    {message_store, word_map_store} =
      if user_id == config.target_user_id do
        # Store the target user message.
        {:ok, message_store} = Repo.Message.insert(message_store, message)

        tokens = Message.tokenize(message)
        Logger.info("Store the message. tokens: #{inspect(tokens)}")

        {:ok, {word_map_store, word_map}} = Repo.WordMap.load(word_map_store)

        word_map = put_message(message, word_map)

        {:ok, word_map_store} = Repo.WordMap.store(word_map_store, word_map)

        {message_store, word_map_store}
      else
        {message_store, word_map_store}
      end

    if Message.is_mention?(message, config.bot_user_id) do
      # It's mension to the bot. Create reply.
      {:ok, {_, word_map}} = Repo.WordMap.load(word_map_store)

      sentence =
        case WordMap.build_sentence(word_map) do
          {:ok, sentence} ->
            Ngram.decode(sentence)

          {:error, :nothing_to_say} ->
            "NO DATA"
        end

      :ok = Replyer.send(replyer, channel_id, sentence)
    end

    %{processor | word_map_store: word_map_store, message_store: message_store}
  end

  @spec put_message(Message.t(), WordMap.t()) :: WordMap.t()
  def put_message(message, word_map) do
    message
    |> Message.tokenize()
    |> Enum.reduce(word_map, fn
      {:text, text}, acc ->
        words = Ngram.encode(text)
        WordMap.put(acc, words)

      _, acc ->
        acc
    end)
  end
end
