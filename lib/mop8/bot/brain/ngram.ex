defmodule Mop8.Bot.Brain.Ngram do
  use GenServer

  require Logger

  alias Mop8.Bot.Repo
  alias Mop8.Bot.Brain.Ngram.Converter
  alias Mop8.Bot.Brain.Ngram.WordMap
  alias Mop8.Bot.Message

  @type words() :: [String.t()]

  @spec start_link(map()) :: GenServer.on_start()
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: Mop8.Bot.Brain)
  end

  @impl GenServer
  def init(args) do
    state = %{word_map_store: args.word_map_store}

    with {:ok, seed} <- Map.fetch(args, :seed) do
      :rand.seed(:default, seed)
    end

    Logger.info("Init #{__MODULE__}. state: #{inspect(state)}")

    {:ok, state, {:continue, :after_init}}
  end

  @impl GenServer
  def handle_continue(:after_init, %{word_map_store: word_map_store} = state) do
    {:ok, {_, word_map}} = Repo.WordMap.load(word_map_store)

    {:noreply, Map.put(state, :word_map, word_map)}
  end

  @impl GenServer
  def handle_call({:learn, message}, _from, %{word_map: word_map} = state) do
    word_map = update_word_map(message, word_map)
    {:ok, _} = Repo.WordMap.store(state.word_map_store, word_map)

    {:reply, :ok, %{state | word_map: word_map}}
  end

  @impl GenServer
  def handle_call({:reply, _hint}, _from, %{word_map: word_map} = state) do
    result =
      with {:ok, sentence} <- WordMap.build_sentence(word_map) do
        {:ok, Converter.decode(sentence)}
      end

    {:reply, result, state}
  end

  @impl GenServer
  def handle_call({:relearn, messages}, _from, %{word_map: word_map} = state) do
    word_map = Enum.reduce(messages, word_map, &update_word_map(&1, &2))
    {:ok, _} = Repo.WordMap.store(state.word_map_store, word_map)

    {:reply, :ok, %{state | word_map: word_map}}
  end

  defp update_word_map(message, word_map) do
    message
    |> Message.tokenize()
    |> Enum.reduce(
      word_map,
      fn
        {:text, text}, acc ->
          words = Converter.encode(text)
          WordMap.put(acc, words)

        _, acc ->
          acc
      end
    )
  end
end
