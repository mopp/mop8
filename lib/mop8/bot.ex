defmodule Mop8.Bot do
  require Logger
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def send_message(message) do
    GenServer.cast(__MODULE__, message)
  end

  @impl GenServer
  def init(_) do
    Logger.info("Init bot.")
    {:ok, nil}
  end

  @impl GenServer
  def handle_cast(msg, state) do
    Logger.info("msg: #{inspect(msg)}")

    {:noreply, state}
  end
end
