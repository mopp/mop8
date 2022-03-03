defmodule Mop8.Console do
  require Logger

  alias Mop8.Bot.Persona
  alias Mop8.Bot.Message

  @channel_id "test_channel_id"

  def mention() do
    "<@#{fetch_bot_id()}>"
    |> Message.new(DateTime.now!("Etc/UTC"))
    |> Persona.talk(fetch_user_id(), @channel_id)
  end

  def say(text) when is_binary(text) do
    Message.new(text, DateTime.now!("Etc/UTC"))
    |> Persona.talk(fetch_user_id(), @channel_id)
  end

  def reconstruct() do
    Persona.reconstruct()
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
        with {:ok, raw_messages} <-
               fetch_raw_messages(fetch_user_id(), fetch_target_channel_id(), oldest, latest) do
          Logger.info("The number of fetched messages: #{length(raw_messages)}")

          Enum.each(raw_messages, fn raw_message ->
            %{
              "text" => text,
              "ts" => message_ts
            } = raw_message

            if String.length(text) != 0 do
              {message_ts, _} = Float.parse(message_ts)
              message_at = DateTime.from_unix!(floor(message_ts * 1_000_000), :microsecond)

              Persona.listen(Message.new(text, message_at))
            end
          end)
        else
          error ->
            error
        end
    end
  end

  defp fetch_bot_id do
    System.fetch_env!("BOT_USER_ID")
  end

  defp fetch_user_id do
    System.fetch_env!("TARGET_USER_ID")
  end

  defp fetch_target_channel_id do
    System.fetch_env!("TARGET_CHANNEL_ID")
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
