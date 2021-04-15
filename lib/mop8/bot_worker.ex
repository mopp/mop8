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
          word_map: word_map
        } = state
      ) do
    word_map = Bot.handle_message(word_map, target_user_id, message)

    Logger.info("word_map: #{inspect(word_map)}")

    {:noreply, %{state | word_map: word_map}}
  end
end
