defmodule Mop8.Slack.Worker do
  use GenServer

  require Logger

  alias Mop8.Bot
  alias Mop8.Bot.Message
  alias Mop8.Repo
  alias Mop8.WordMapStore
  alias Mop8.MessageStore

  @spec start_link(any()) :: GenServer.on_start()
  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @spec handle_payload(map()) :: :ok
  def handle_payload(payload) do
    GenServer.cast(__MODULE__, {:payload, payload})
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
      # FIXME: Inject them and write test.
      word_map_store: WordMapStore.new(),
      message_store: MessageStore.new()
    }

    {:ok, state, {:continue, nil}}
  end

  @impl GenServer
  def handle_continue(_, %{word_map_store: word_map_store, message_store: message_store} = state) do
    with {:ok, {word_map_store, word_map}} <- Repo.WordMap.load(word_map_store),
         {:ok, {message_store, _messages}} <- Repo.Message.all(message_store) do
      Logger.info("WordMap and Message are loaded.")

      state =
        state
        |> Map.put(:word_map, word_map)
        |> Map.put(:word_map_store, word_map_store)
        |> Map.put(:message_store, message_store)

      {:noreply, state}
    else
      {:error, reason} ->
        {:stop, {"Loading data failed.", reason}}
    end
  end

  @impl GenServer
  def handle_cast(
        {:payload, payload},
        %{
          bot_config: bot_config,
          target_channel_id: target_channel_id,
          word_map: word_map,
          word_map_store: word_map_store,
          message_store: message_store
        } = state
      ) do
    state =
      case payload do
        %{
          "type" => "event_callback",
          "event" => %{
            "event_ts" => event_ts,
            "text" => text,
            "type" => "message",
            "user" => user_id
          }
        } ->
          {event_ts, _} = Float.parse(event_ts)
          event_at = DateTime.from_unix!(floor(event_ts * 1_000_000), :microsecond)

          message = Message.new(user_id, text, event_at)

          case Bot.handle_message(word_map, message, bot_config) do
            {:ok, {:reply, sentence}} ->
              Logger.info("Reply: #{sentence}")

              response = Slack.Web.Chat.post_message(target_channel_id, sentence)
              Logger.info("Response: #{inspect(response)}")

              state

            {:ok, {:update, word_map}} ->
              Logger.info("WordMap updated: #{inspect(word_map)}")

              {:ok, message_store} = Repo.Message.insert(message_store, message)
              {:ok, word_map_store} = Repo.WordMap.store(word_map_store, word_map)

              %{
                state
                | word_map: word_map,
                  word_map_store: word_map_store,
                  message_store: message_store
              }

            {:ok, :ignore} ->
              Logger.info("Ignored")

              state
          end

        _ ->
          state
      end

    {:noreply, state}
  end
end
