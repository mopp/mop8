defmodule Mop8.Slack.SocketMode.Client do
  require Logger
  alias Mop8.Bot
  use WebSockex

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
    Logger.info("Connected.")

    {:ok, state}
  end

  @impl WebSockex
  def handle_disconnect(connection_status_map, state) do
    Logger.info("Disconnected. #{inspect(connection_status_map)}")

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

    IO.inspect("Frame received. message: #{inspect(message)}")

    case message["type"] do
      "hello" ->
        {:ok, state}

      "events_api" ->
        Bot.send_message(message)

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
    IO.inspect("handle_cast: #{inspect(frame)}")

    {:reply, frame, state}
  end

  @impl WebSockex
  def handle_info(msg, state) do
    IO.inspect("handle_info: #{inspect(msg)}")

    {:ok, state}
  end

  @impl WebSockex
  def terminate(reason, _state) do
    IO.inspect("terminate. reason: #{inspect(reason)}")

    :ok
  end

  defp fetch_url do
    HTTPoison.start()

    url = "https://slack.com/api/apps.connections.open"

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", "Bearer #{System.fetch_env!("SLACK_APP_LEVEL_TOKEN")}"}
    ]

    with {:ok, response} <- HTTPoison.post(url, "", headers),
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
