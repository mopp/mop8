defmodule Mop8.Bot.Config do
  alias Mop8.Bot.Error.ConfigError

  @enforce_keys [
    :target_user_id,
    :bot_user_id
  ]

  defstruct [
    :target_user_id,
    :bot_user_id
  ]

  @type t :: %__MODULE__{
          target_user_id: String.t(),
          bot_user_id: String.t()
        }

  @spec new(String.t(), String.t()) :: t()
  def new(target_user_id, bot_user_id) do
    if !is_binary(target_user_id) || String.length(target_user_id) == 0 do
      msg = "The target user ID must be non empty string. target_user_id: #{target_user_id}"

      raise ConfigError, msg
    end

    if !is_binary(bot_user_id) || String.length(bot_user_id) == 0 do
      msg = "The bot user ID must be non empty string. bot_user_id: #{target_user_id}"

      raise ConfigError, msg
    end

    %__MODULE__{
      target_user_id: target_user_id,
      bot_user_id: bot_user_id
    }
  end
end
