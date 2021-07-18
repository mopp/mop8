defmodule Mop8.Maintainer do
  use GenServer

  require Logger

  alias Mop8.Bot.Message
  alias Mop8.Bot.Processor
  alias Mop8.Bot.Repo
  alias Mop8.Bot.WordMap

  @spec start_link({String.t(), String.t(), Repo.Message.t(), Repo.WordMap.t()}) ::
          GenServer.on_start()
  def start_link({target_user_id, target_channel_id, message_store, word_map_store})
      when is_binary(target_user_id) and is_binary(target_channel_id) do
    state = %{
      target_user_id: target_user_id,
      target_channel_id: target_channel_id,
      message_store: message_store,
      word_map_store: word_map_store
    }

    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @spec refetch_messages(String.t(), String.t()) :: :ok | {:error, reason :: any()}
  def refetch_messages(oldest, latest) when is_binary(oldest) and is_binary(latest) do
    {:ok, oldest, _utc_offset} = DateTime.from_iso8601(oldest)
    {:ok, latest, _utc_offset} = DateTime.from_iso8601(latest)

    refetch_messages(oldest, latest)
  end

  @spec refetch_messages(DateTime.t(), DateTime.t()) :: :ok | {:error, reason :: any()}
  def refetch_messages(oldest, latest) do
    cond do
      !is_datetime?(oldest) ->
        {:error, "the given oldest is not DateTime. #{oldest}"}

      !is_datetime?(latest) ->
        {:error, "the given latest is not DateTime. #{latest}"}

      true ->
        GenServer.call(__MODULE__, {:refetch_messages, {oldest, latest}}, 600_000)
    end
  end

  def rebuild_word_map() do
    GenServer.call(__MODULE__, :rebuild_word_map)
  end

  @impl GenServer
  def init(state) do
    Logger.info("Init #{__MODULE__}. state: #{inspect(state)}")

    {:ok, state}
  end

  @impl GenServer
  def handle_call({:refetch_messages, {oldest, latest}}, _from, state) do
    %{
      target_user_id: target_user_id,
      target_channel_id: target_channel_id,
      message_store: message_store
    } = state

    with {:ok, raw_messages} <-
           fetch_raw_messages(target_user_id, target_channel_id, oldest, latest) do
      Logger.info("The number of fetched messages: #{length(raw_messages)}")

      message_store =
        Enum.reduce(raw_messages, message_store, fn
          raw_message, message_store ->
            %{
              "text" => text,
              "ts" => message_ts,
              "user" => user_id
            } = raw_message

            if String.length(text) != 0 do
              {message_ts, _} = Float.parse(message_ts)
              message_at = DateTime.from_unix!(floor(message_ts * 1_000_000), :microsecond)
              message = Message.new(user_id, text, message_at, target_channel_id)

              {:ok, message_store} = Repo.Message.insert(message_store, message)
              message_store
            else
              message_store
            end
        end)

      {:reply, :ok, %{state | message_store: message_store}}
    else
      error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call(:rebuild_word_map, _from, state) do
    %{
      message_store: message_store,
      word_map_store: word_map_store
    } = state

    reply =
      with {:ok, {_, messages}} <- Repo.Message.all(message_store),
           word_map <- Enum.reduce(messages, WordMap.new(), &Processor.put_message/2),
           {:ok, _} <- Repo.WordMap.store(word_map_store, word_map) do
        :ok
      end

    {:reply, reply, state}
  end

  defp is_datetime?(x) do
    is_struct(x) && DateTime == x.__struct__
  end

  defp fetch_raw_messages(target_user_id, target_channel_id, oldest, latest) do
    Logger.info("Fetch messages in [#{oldest}, #{latest}]")

    opts = %{
      oldest: to_slack_timestamp(oldest),
      latest: to_slack_timestamp(latest),
      inclusive: true
    }

    fetch_conversations_history(target_user_id, target_channel_id, opts, [])
  end

  defp to_slack_timestamp(datetime) do
    "#{DateTime.to_unix(datetime)}.000000"
  end

  defp fetch_conversations_history(target_user_id, target_channel_id, opts, messages) do
    with %{
           "ok" => true,
           "messages" => received_messages,
           "has_more" => has_more
         } = response <- Slack.Web.Conversations.history(target_channel_id, opts) do
      messages =
        Enum.reduce(received_messages, messages, fn
          %{"user" => ^target_user_id} = raw_message, acc ->
            [raw_message | acc]

          _, acc ->
            acc
        end)

      if has_more do
        opts = Map.put(opts, :cursor, response["response_metadata"]["next_cursor"])
        fetch_conversations_history(target_user_id, target_channel_id, opts, messages)
      else
        {:ok, messages}
      end
    else
      %{
        "ok" => false,
        "error" => reason
      } ->
        {:error, reason}

      response ->
        {:error, {:unexpected, response}}
    end
  end
end
