defmodule Mop8.BotWorker do
  require Logger
  alias Mop8.Bot
  alias Mop8.WordMap
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
      target_channel_id: System.fetch_env!("TARGET_CHANNEL_ID"),
      target_user_id: System.fetch_env!("TARGET_USER_ID"),
      bot_user_id: System.fetch_env!("BOT_USER_ID"),
      filepath: System.fetch_env!("MOP8_WORD_MAP_FILEPATH")
    }

    {:ok, state, {:continue, nil}}
  end

  @impl GenServer
  def handle_continue(_, %{filepath: filepath} = state) do
    case WordMap.load(filepath) do
      {:ok, word_map} ->
        {:noreply, Map.put(state, :word_map, word_map)}

      {:error, reason} ->
        {:stop, {:loading_word_map_failed, reason}, state}
    end
  end

  @impl GenServer
  def handle_cast(
        {:message, message},
        %{
          target_channel_id: target_channel_id,
          target_user_id: target_user_id,
          bot_user_id: bot_user_id,
          filepath: filepath,
          word_map: word_map
        } = state
      ) do
    state =
      case Bot.handle_message(word_map, target_user_id, bot_user_id, message) do
        {:ok, {:reply, sentence}} ->
          Logger.info("Reply: #{sentence}")

          response = Slack.Web.Chat.post_message(target_channel_id, sentence)
          Logger.info("Response: #{inspect(response)}")

          state

        {:ok, {:update, word_map}} ->
          Logger.info("WordMap updated: #{inspect(word_map)}")

          :ok = WordMap.store(filepath, word_map)

          %{state | word_map: word_map}

        {:ok, :ignore} ->
          state
      end

    {:noreply, state}
  end
end
