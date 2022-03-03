defmodule Mop8.Bot.Persona do
  use GenServer

  require Logger

  alias Mop8.Bot.Config
  alias Mop8.Bot.Message
  alias Mop8.Bot.Ngram
  alias Mop8.Bot.Replyer
  alias Mop8.Bot.Repo
  alias Mop8.Bot.WordMap

  @spec start_link({Config.t(), Repo.WordMap.t(), Repo.Message.t(), Replyer.t()}) ::
          GenServer.on_start()
  def start_link({config, word_map_store, message_store, replyer}) do
    GenServer.start_link(
      __MODULE__,
      %{
        config: config,
        word_map_store: word_map_store,
        message_store: message_store,
        replyer: replyer
      },
      name: __MODULE__
    )
  end

  @spec talk(Message.t(), String.t(), String.t()) :: :ok
  def talk(message, user_id, channel_id) when is_binary(user_id) and is_binary(channel_id) do
    GenServer.call(__MODULE__, {:talk, {message, user_id, channel_id}}, 600_000)
  end

  @impl GenServer
  def init(state) do
    Logger.info("Init #{__MODULE__}. state: #{inspect(state)}")

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:talk, {message, user_id, channel_id}}, _from, state) do
    %{
      config: config,
      word_map_store: word_map_store,
      message_store: message_store,
      replyer: replyer
    } = state

    {message_store, word_map_store} =
      if user_id == config.target_user_id do
        store_message(message, message_store, word_map_store)
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

    {:reply, :ok, %{state | word_map_store: word_map_store, message_store: message_store}}
  end

  defp store_message(message, message_store, word_map_store) do
    {:ok, message_store} = Repo.Message.insert(message_store, message)

    tokens = Message.tokenize(message)
    Logger.info("Store the message. tokens: #{inspect(tokens)}")

    {:ok, {word_map_store, word_map}} = Repo.WordMap.load(word_map_store)

    word_map = put_message(message, word_map)

    {:ok, word_map_store} = Repo.WordMap.store(word_map_store, word_map)

    {message_store, word_map_store}
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
