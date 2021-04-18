defmodule Mop8.Slack.Worker do
  require Logger
  alias Mop8.Bot
  alias Mop8.WordMap
  use GenServer

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec send_message(Bot.message()) :: :ok
  def send_message(message) do
    GenServer.cast(__MODULE__, {:message, message})
  end

  @impl GenServer
  def init(_) do
    Logger.info("Init #{__MODULE__}.")

    state = %{
      bot_config:
        Bot.Config.new(
          System.fetch_env!("TARGET_USER_ID"),
          System.fetch_env!("BOT_USER_ID")
        ),
      target_channel_id: System.fetch_env!("TARGET_CHANNEL_ID"),
      filepath: System.fetch_env!("MOP8_WORD_MAP_FILEPATH")
    }

    {:ok, state, {:continue, nil}}
  end

  @impl GenServer
  def handle_continue(_, %{filepath: filepath} = state) do
    case WordMap.load(filepath) do
      {:ok, word_map} ->
        Logger.info("Load WordMap.")

        {:noreply, Map.put(state, :word_map, word_map)}

      {:error, reason} ->
        {:stop, {:loading_word_map_failed, reason}, state}
    end
  end

  @impl GenServer
  def handle_cast(
        {:message, {user_id, text, event_ts}},
        %{
          bot_config: bot_config,
          target_channel_id: target_channel_id,
          filepath: filepath,
          word_map: word_map
        } = state
      ) do
    {event_ts, _} = Float.parse(event_ts)
    event_at = DateTime.from_unix!(floor(event_ts * 1_000_000), :microsecond)

    message = Bot.Message.new(user_id, text, event_at)

    state =
      case Bot.handle_message(word_map, message, bot_config) do
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
          Logger.info("Ignored")

          state
      end

    {:noreply, state}
  end
end
