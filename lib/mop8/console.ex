defmodule Mop8.Console do
  alias Mop8.Adapter.MessageController

  def mention() do
    say("<@#{System.fetch_env!("BOT_USER_ID")}>うみゃー")
  end

  def say(text) when is_binary(text) do
    %{
      "type" => "event_callback",
      "event" => %{
        "type" => "message",
        "user" => System.fetch_env!("TARGET_USER_ID"),
        "text" => text,
        "channel" => "test_channel_id",
        "event_ts" => "0"
      }
    }
    |> MessageController.handle_payload()
  end
end
