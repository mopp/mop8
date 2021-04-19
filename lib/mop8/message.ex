defmodule Mop8.Message do
  alias Mop8.Error.InvalidMessageError

  @enforce_keys [
    :user_id,
    :text,
    :event_at
  ]

  defstruct [
    :user_id,
    :text,
    :event_at
  ]

  @type t :: %__MODULE__{
          user_id: String.t(),
          text: String.t(),
          event_at: DateTime.t()
        }

  @spec new(String.t(), String.t(), DateTime.t()) :: t()
  def new(user_id, text, event_at) do
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

    %__MODULE__{
      user_id: user_id,
      text: text,
      event_at: event_at
    }
  end
end
