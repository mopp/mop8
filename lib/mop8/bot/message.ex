defmodule Mop8.Bot.Message do
  alias Mop8.Bot.Error.InvalidMessageError

  @enforce_keys [
    :text,
    :event_at
  ]

  defstruct [
    :text,
    :event_at
  ]

  @type t :: %__MODULE__{
          text: String.t(),
          event_at: DateTime.t()
        }

  @spec new(String.t(), DateTime.t()) :: t()
  def new(text, event_at) do
    if !is_binary(text) || String.length(text) == 0 do
      msg = "The text must be non empty string. text: #{text}"

      raise InvalidMessageError, msg
    end

    if !is_struct(event_at) || DateTime != event_at.__struct__ do
      msg = "The event_at must be DateTime. event_at: #{event_at}"

      raise InvalidMessageError, msg
    end

    %__MODULE__{
      text: text,
      event_at: event_at
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
    String.split(text, ~r/<.+>|```(\s|.)*```|\*.*\*|&gt;.*|^\/.*/,
      include_captures: true,
      trim: true
    )
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

        String.match?(text, ~r/^\/.*$/) ->
          {:command, String.trim(text)}

        String.match?(text, ~r/^:.*:$/) ->
          {:emoji_only, text}

        true ->
          nil
      end

    if token == nil do
      case String.trim(text) do
        "" ->
          tokenize(rest, acc)

        text ->
          acc =
            String.split(text, "\n", trim: true)
            |> Enum.reduce(acc, fn text, acc ->
              [{:text, text} | acc]
            end)

          tokenize(rest, acc)
      end
    else
      tokenize(rest, [token | acc])
    end
  end
end
