defmodule Mop8.Slack.Bot do
  require Logger
  use WebSockex

  def start_link(url) do
    WebSockex.start_link(url, __MODULE__, nil)
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
    message = Poison.decode!(message)
    IO.inspect("frame received. message: #{inspect(message)}")

    {:ok, state}
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
end
