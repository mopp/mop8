defmodule Mop8.Console do
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

  defp fetch_bot_id do
    System.fetch_env!("BOT_USER_ID")
  end

  defp fetch_user_id do
    System.fetch_env!("TARGET_USER_ID")
  end
end
