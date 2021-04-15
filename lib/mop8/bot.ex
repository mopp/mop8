defmodule Mop8.Bot do
  require Logger

  def handle_message(word_map, _target_user_id, message) do
    Logger.info("message: #{inspect(message)}")

    word_map
  end
end
