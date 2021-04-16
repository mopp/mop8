defmodule Mop8.Tokenizer do
  @type token() :: {:user_id, String.t()} | {:text, String.t()}

  @spec tokenize(String.t()) :: [token()]
  def tokenize(text) do
    text
    |> split()
    |> tokenize([])
    |> Enum.reverse()
  end

  defp split(text) do
    String.split(text, ~r/<.+>|```(\s|.)*```|\*.*\*|&gt;.*\n/, include_captures: true, trim: true)
  end

  defp tokenize([], acc) do
    acc
  end

  defp tokenize([text | rest], acc) do
    token =
      cond do
        String.match?(text, ~r/^<@.+>$/) ->
          {:user_id, String.slice(text, 2..-2)}

        String.match?(
          text,
          ~r/^<https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)>$/
        ) ->
          {:uri, String.slice(text, 1..-2)}

        String.match?(text, ~r/^```(\s|.)*```$/) ->
          {:code, String.slice(text, 3..-4)}

        String.match?(text, ~r/^\*.+\*$/) ->
          {:bold, String.slice(text, 1..-2)}

        String.match?(text, ~r/^&gt;.*\n$/) ->
          {:quote, String.slice(text, 5..-2)}

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
