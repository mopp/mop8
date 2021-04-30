defmodule Mop8.Console do
  alias Mop8.Adapter.MessageController

  def mention() do
    %{
      "type" => "event_callback",
      "event" => %{
        "type" => "message",
        "user" => "test_user_id",
        "text" => "<@#{System.fetch_env!("BOT_USER_ID")}>うみゃー",
        "channel" => "test_channel_id",
        "event_ts" => "0"
      }
    }
    |> MessageController.handle_payload()
  end
end
