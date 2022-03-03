defmodule Mop8.Adapter.MessageController do
  use GenServer

  require Logger

  alias Mop8.Bot.Message
  alias Mop8.Bot.Persona

  @spec start_link(Persona.t()) :: GenServer.on_start()
  def start_link(persona) do
    GenServer.start_link(__MODULE__, %{persona: persona}, name: __MODULE__)
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
  def handle_cast({:payload, payload}, %{persona: persona} = state) do
    persona = handle_payload(payload, persona)

    {:noreply, %{state | persona: persona}}
  end

  defp handle_payload(payload, persona) do
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

        persona.process_message(persona, message, user_id, channel_id)

      _ ->
        persona
    end
  end
end
