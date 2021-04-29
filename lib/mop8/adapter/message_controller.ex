defmodule Mop8.Adapter.MessageController do
  use GenServer

  require Logger

  alias Mop8.Bot.Message
  alias Mop8.Bot.Processor

  @spec start_link(Processor.t()) :: GenServer.on_start()
  def start_link(processor) do
    GenServer.start_link(__MODULE__, %{processor: processor}, name: __MODULE__)
  end

  @spec handle_payload(map()) :: :ok
  def handle_payload(payload) do
    GenServer.cast(__MODULE__, {:payload, payload})
  end

  @impl GenServer
  def init(state) do
    Logger.info("Init #{__MODULE__}.")

    {:ok, state}
  end

  @impl GenServer
  def handle_cast({:payload, payload}, %{processor: processor} = state) do
    processor = handle_payload(payload, processor)

    {:noreply, %{state | processor: processor}}
  end

  defp handle_payload(payload, processor) do
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

        message = Message.new(user_id, text, event_at, channel_id)

        Processor.process_message(processor, message)

      _ ->
        processor
    end
  end
end
