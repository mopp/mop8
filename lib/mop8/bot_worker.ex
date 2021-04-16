defmodule Mop8.BotWorker do
  require Logger
  alias Mop8.Bot
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def send_message(message) do
    GenServer.cast(__MODULE__, {:message, message})
  end

  @impl GenServer
  def init(_) do
    Logger.info("Init bot.")

    state = %{
      target_user_id: System.fetch_env!("TARGET_USER_ID"),
      bot_user_id: System.fetch_env!("BOT_USER_ID"),
      # TODO: Read WordMap from store.
      word_map: Mop8.WordMap.new()
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_cast(
        {:message, message},
        %{
          target_user_id: target_user_id,
          bot_user_id: bot_user_id,
          word_map: word_map
        } = state
      ) do
    state =
      case Bot.handle_message(word_map, target_user_id, bot_user_id, message) do
        {:ok, {:reply, sentence}} ->
          Logger.info("Reply: #{sentence}")
          state

        {:ok, {:update, word_map}} ->
          Logger.info("WordMap updated: #{inspect(word_map)}")
          %{state | word_map: word_map}

        {:ok, :ignore} ->
          state
      end

    {:noreply, state}
  end
end
