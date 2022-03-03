defmodule Mop8.Adapter.Slack.SocketMode.Client do
  use WebSockex

  require Logger

  @slack_api_url "https://slack.com/api/apps.connections.open"

  @spec start_link(String.t()) :: {:ok, pid()} | {:error, term()}
  def start_link(app_level_token) when is_binary(app_level_token) do
    WebSockex.start_link(fetch_url(app_level_token), __MODULE__, nil)
  end

  @impl WebSockex
  def handle_connect(_conn, state) do
    Logger.info("#{__MODULE__} connected.")

    {:ok, state}
  end

  @impl WebSockex
  def handle_disconnect(connection_status_map, state) do
    Logger.info("#{__MODULE__} disconnected. #{inspect(connection_status_map)}")

    {:ok, state}
  end

  @impl WebSockex
  def handle_frame({:text, message}, state) do
    message =
      try do
        Poison.decode!(message)
      rescue
        error ->
          Logger.error("Poison.decode! error: #{inspect(error)}, message: #{message}")
          raise error
      end

    case message["type"] do
      "hello" ->
        Logger.info("Hello from Slack.")

        {:ok, state}

      "disconnect" ->
        # https://api.slack.com/apis/connections/socket-implement#disconnect
        {:close, state}

      "events_api" ->
        payload = message["payload"]

        Logger.info("Event API payload: #{inspect(payload)}")

        case payload do
          %{
            "type" => "event_callback",
            "event" => %{
              "type" => "message",
              "user" => user_id,
              "text" => text,
              "channel" => channel_id,
              "event_ts" => event_ts
            }
          } ->
            {event_ts, _} = Float.parse(event_ts)
            event_at = DateTime.from_unix!(floor(event_ts * 1_000_000), :microsecond)

            message = Message.new(text, event_at)

            Persona.talk(message, user_id, channel_id)

          _ ->
            nil
        end

        body = Poison.encode!(%{envelope_id: message["envelope_id"]})

        {:reply, {:text, body}, state}
    end
  end

  @impl WebSockex
  def handle_cast({:send, {_type, _msg} = frame}, state) do
    Logger.info("handle_cast: #{inspect(frame)}")

    {:reply, frame, state}
  end

  @impl WebSockex
  def terminate(reason, _state) do
    Logger.info("terminate. reason: #{inspect(reason)}")

    :ok
  end

  defp fetch_url(app_level_token) do
    {:ok, _} = HTTPoison.start()

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", "Bearer #{app_level_token}"}
    ]

    {:ok, response} = HTTPoison.post(@slack_api_url, "", headers)

    if response.status_code != 200 do
      raise "request failed to fetch WebSocket URL. response: #{inspect(response)}"
    end

    {:ok, body} = Poison.decode(response.body)
    %{"ok" => true, "url" => websocket_url} = body

    websocket_url
  end
end
