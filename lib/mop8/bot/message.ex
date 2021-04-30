defmodule Mop8.Bot.Message do
  alias Mop8.Bot.Error.InvalidMessageError

  @enforce_keys [
    :user_id,
    :text,
    :event_at,
    :channel_id
  ]

  defstruct [
    :user_id,
    :text,
    :event_at,
    :channel_id
  ]

  @type t :: %__MODULE__{
          user_id: String.t(),
          text: String.t(),
          event_at: DateTime.t(),
          channel_id: String.t()
        }

  @spec new(String.t(), String.t(), DateTime.t(), String.t()) :: t()
  def new(user_id, text, event_at, channel_id) do
    if !is_binary(user_id) || String.length(user_id) == 0 do
      msg = "The user ID must be non empty string. user_id: #{user_id}"

      raise InvalidMessageError, msg
    end

    if !is_binary(text) || String.length(text) == 0 do
      msg = "The text must be non empty string. text: #{text}"

      raise InvalidMessageError, msg
    end

    if !is_struct(event_at) || DateTime != event_at.__struct__ do
      msg = "The event_at must be DateTime. event_at: #{event_at}"

      raise InvalidMessageError, msg
    end

    if !is_binary(channel_id) || String.length(channel_id) == 0 do
      msg = "The channel ID must be non empty string. channel_id: #{channel_id}"

      raise InvalidMessageError, msg
    end

    %__MODULE__{
      user_id: user_id,
      text: text,
      event_at: event_at,
      channel_id: channel_id
    }
  end

  @spec is_mention?(t(), String.t()) :: boolean()
  def is_mention?(%__MODULE__{text: text}, user_id) do
    String.match?(text, ~r/^<@#{user_id}>/)
  end
end
