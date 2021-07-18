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

  @spec tokenize(t()) :: [token]
        when token:
               {:user_id, String.t()}
               | {:url, String.t()}
               | {:code, String.t()}
               | {:bold, String.t()}
               | {:quote, String.t()}
               | {:text, String.t()}
  def tokenize(%__MODULE__{text: text}) do
    text
    |> split()
    |> tokenize([])
    |> Enum.reverse()
  end

  defp split(text) do
    String.split(text, ~r/<.+>|```(\s|.)*```|\*.*\*|&gt;.*/, include_captures: true, trim: true)
  end

  defp tokenize([], acc) do
    acc
  end

  defp tokenize([text | rest], acc) do
    token =
      cond do
        String.match?(text, ~r/^<@.+>$/) ->
          {:user_id, String.slice(text, 2..-2)}

        String.match?(text, ~r/^<http.*>$/) ->
          {:uri, String.slice(text, 1..-2)}

        String.match?(text, ~r/^```(\s|.)*```$/) ->
          {:code, String.slice(text, 3..-4)}

        String.match?(text, ~r/^\*.+\*$/) ->
          {:bold, String.slice(text, 1..-2)}

        String.match?(text, ~r/^&gt;.*$/) ->
          {:quote, String.slice(text, 5..-1)}

        true ->
          {:text, String.trim(text)}
      end

    if token == {:text, ""} do
      tokenize(rest, acc)
    else
      tokenize(rest, [token | acc])
    end
  end
end
