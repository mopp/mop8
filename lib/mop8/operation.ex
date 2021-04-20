defmodule Mop8.Operation do
  require Logger

  alias Mop8.Bot
  alias Mop8.Message
  alias Mop8.MessageStore
  alias Mop8.Repo
  alias Mop8.WordMapStore

  def fetch_and_rebuild(oldest, latest) when is_binary(oldest) and is_binary(latest) do
    filepath =
      [System.fetch_env!("MOP8_STORAGE_DIR"), "messages.json"]
      |> Path.join()
      |> Path.expand()

    # TODO: Create Repo.Message.delete and Repo.Message.insert_all
    with {:ok, messages} <- fetch_messages(oldest, latest),
         {:ok, raw_json} <- Poison.encode(messages),
         :ok <- File.write(filepath, raw_json) do
      config =
        Bot.Config.new(
          System.fetch_env!("TARGET_USER_ID"),
          System.fetch_env!("BOT_USER_ID")
        )

      word_map = Bot.rebuild_word_map(messages, config)

      # TODO: Create Repo.WordMap.delete
      WordMapStore.new()
      |> Repo.WordMap.store(word_map)
    end
  end

  def rebuild_word_map_by_all_messages do
    {:ok, {_, messages}} = Repo.Message.all(MessageStore.new())

    config =
      Bot.Config.new(
        System.fetch_env!("TARGET_USER_ID"),
        System.fetch_env!("BOT_USER_ID")
      )

    word_map = Bot.rebuild_word_map(messages, config)

    # TODO: Create Repo.WordMap.delete
    WordMapStore.new()
    |> Repo.WordMap.store(word_map)
  end

  defp fetch_messages(oldest, latest) do
    target_user_id = System.fetch_env!("TARGET_USER_ID")
    target_channel_id = System.fetch_env!("TARGET_CHANNEL_ID")

    Logger.info("Fetch messages in [#{oldest}, #{latest}]")

    opts = %{
      oldest: to_slack_timestamp(oldest),
      latest: to_slack_timestamp(latest),
      inclusive: true
    }

    fetch_conversations_history(target_user_id, target_channel_id, opts, [])
  end

  defp fetch_conversations_history(target_user_id, target_channel_id, opts, messages) do
    case Slack.Web.Conversations.history(target_channel_id, opts) do
      %{
        "ok" => true,
        "messages" => received_messages,
        "has_more" => has_more
      } = response ->
        messages =
          Enum.reduce(received_messages, messages, fn
            %{"text" => text, "ts" => message_ts, "user" => ^target_user_id}, acc ->
              {message_ts, _} = Float.parse(message_ts)
              message_at = DateTime.from_unix!(floor(message_ts * 1_000_000), :microsecond)

              [Message.new(target_user_id, text, message_at) | acc]

            _, acc ->
              acc
          end)

        if has_more do
          # Fetch messages more.
          opts = Map.put(opts, :cursor, response["response_metadata"]["next_cursor"])
          fetch_conversations_history(target_user_id, target_channel_id, opts, messages)
        else
          {:ok, messages}
        end

      %{
        "ok" => false,
        "error" => reason
      } ->
        {:error, reason}

      response ->
        {:error, {:unexpected, response}}
    end
  end

  defp to_slack_timestamp(raw_datetime) when is_binary(raw_datetime) do
    {:ok, datetime, _} = DateTime.from_iso8601(raw_datetime)
    "#{DateTime.to_unix(datetime)}.000000"
  end
end
