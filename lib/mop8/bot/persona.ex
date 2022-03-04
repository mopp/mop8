defmodule Mop8.Bot.Persona do
  use GenServer

  require Logger

  alias Mop8.Bot.Config
  alias Mop8.Bot.Message
  alias Mop8.Bot.Replyer
  alias Mop8.Bot.Repo
  alias Mop8.Bot.Brain

  @spec talk(Message.t(), String.t(), String.t()) :: :ok
  def talk(message, user_id, channel_id) when is_binary(user_id) and is_binary(channel_id) do
    GenServer.call(__MODULE__, {:talk, {message, user_id, channel_id}}, 600_000)
  end

  @spec reconstruct() :: :ok
  def reconstruct do
    GenServer.call(__MODULE__, :reconstruct)
  end

  @spec listen(Message.t()) :: :ok
  def listen(messages) do
    :ok = GenServer.call(__MODULE__, {:listen, messages})
  end

  @spec start_link({Config.t(), Repo.Message.t(), Replyer.t()}) :: GenServer.on_start()
  def start_link({config, message_store, replyer}) do
    GenServer.start_link(
      __MODULE__,
      %{
        config: config,
        message_store: message_store,
        replyer: replyer
      },
      name: __MODULE__
    )
  end

  @impl GenServer
  def init(state) do
    Logger.info("Init #{__MODULE__}. state: #{inspect(state)}")

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:talk, {message, user_id, channel_id}}, _from, %{config: config} = state) do
    message_store =
      if user_id == config.target_user_id do
        with :ok <- Brain.learn(message),
             {:ok, message_store} = Repo.Message.insert(state.message_store, message) do
          message_store
        end
      else
        state.message_store
      end

    if Message.is_mention?(message, config.bot_user_id) do
      # It's mension to the bot. Create reply.
      sentence =
        case Brain.reply({}) do
          {:ok, sentence} ->
            sentence

          {:error, :nothing_to_say} ->
            "NO DATA"
        end

      :ok = Replyer.send(state.replyer, channel_id, sentence)
    end

    {:reply, :ok, %{state | message_store: message_store}}
  end

  @impl GenServer
  def handle_call(:reconstruct, _from, state) do
    # TODO: Accept only the messages which are from the target users.
    with {:ok, {_, messages}} <- Repo.Message.all(state[:message_store]),
         :ok <- Brain.relearn(messages) do
      {:reply, :ok, state}
    else
      {:error, _reason} = err ->
        {:reply, err, state}
    end
  end

  def handle_call({:listen, message}, _from, %{message_store: message_store} = state) do
    {:ok, message_store} = Repo.Message.insert(message_store, message)

    {:reply, :ok, %{state | message_store: message_store}}
  end
end
