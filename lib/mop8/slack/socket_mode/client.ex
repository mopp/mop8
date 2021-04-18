defmodule Mop8.Slack.SocketMode.Client do
  require Logger
  alias Mop8.BotWorker
  use WebSockex

  @slack_api_url "https://slack.com/api/apps.connections.open"

  @spec start_link(any()) :: {:ok, pid()} | {:error, term()}
  def start_link(_) do
    with {:ok, websocket_url} <- fetch_url() do
      WebSockex.start_link(websocket_url, __MODULE__, nil)
    else
      {:error, reason} ->
        {:error, {:fetch_endpoint, reason}}
    end
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

      "events_api" ->
        Logger.info("Event API: #{inspect(message["payload"])}")

        case message["payload"] do
          %{
            "type" => "event_callback",
            "event" => %{
              "event_ts" => event_ts,
              "text" => text,
              "type" => "message",
              "user" => user
            }
          } ->
            BotWorker.send_message({user, text, event_ts})

          _ ->
            nil
        end

        body =
          %{
            envelope_id: message["envelope_id"]
          }
          |> Poison.encode!()

        {:reply, {:text, body}, state}
    end
  end

  @impl WebSockex
  def handle_cast({:send, {_type, _msg} = frame}, state) do
    Logger.info("handle_cast: #{inspect(frame)}")

    {:reply, frame, state}
  end

  @impl WebSockex
  def handle_info(msg, state) do
    Logger.info("handle_info: #{inspect(msg)}")

    {:ok, state}
  end

  @impl WebSockex
  def terminate(reason, _state) do
    Logger.info("terminate. reason: #{inspect(reason)}")

    :ok
  end

  defp fetch_url do
    {:ok, _} = HTTPoison.start()

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", "Bearer #{System.fetch_env!("SLACK_APP_LEVEL_TOKEN")}"}
    ]

    with {:ok, response} <- HTTPoison.post(@slack_api_url, "", headers),
         200 <- response.status_code,
         {:ok, slack_response} <- Poison.decode(response.body) do
      case slack_response do
        %{"ok" => true, "url" => websocket_url} ->
          {:ok, websocket_url}

        %{"ok" => false, "error" => reason} ->
          {:error, reason}
      end
    else
      error ->
        error
    end
  end
end
