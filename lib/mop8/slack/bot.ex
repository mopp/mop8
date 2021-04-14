defmodule Mop8.Slack.Bot do
  use WebSockex

  def start_link(url) do
    WebSockex.start_link(url, __MODULE__, nil)
  end

  @impl WebSockex
  def handle_frame({_type, _msg}, state) do
    {:ok, state}
  end

  @impl WebSockex
  def handle_cast({:send, {_type, _msg} = frame}, state) do
    {:reply, frame, state}
  end
end
