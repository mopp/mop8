defmodule Mop8.Adapter.Slack.SocketMode.Client do
  use WebSockex

  require Logger

  alias Mop8.Adapter.MessageController

  @slack_api_url "https://slack.com/api/apps.connections.open"

  @spec start_link(String.t()) :: {:ok, pid()} | {:error, term()}
  def start_link(app_level_token) when is_binary(app_level_token) do
    with {:ok, websocket_url} <- fetch_url(app_level_token) do
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
        payload = message["payload"]

        Logger.info("Event API payload: #{inspect(payload)}")

        MessageController.handle_payload(payload)

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
  def handle_info(msg, state) do
    Logger.info("handle_info: #{inspect(msg)}")

    {:ok, state}
  end

  @impl WebSockex
  def terminate(reason, _state) do
    Logger.info("terminate. reason: #{inspect(reason)}")

    :ok
  end

  defp fetch_url(app_level_token) do
    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", "Bearer #{app_level_token}"}
    ]

    with {:ok, _} <- HTTPoison.start(),
         {:ok, response} <- HTTPoison.post(@slack_api_url, "", headers),
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
