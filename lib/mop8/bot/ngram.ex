defmodule Mop8.Bot.Ngram do
  @type words() :: [String.t()]

  @spec encode(String.t(), pos_integer()) :: words()
  def encode(text, n \\ 2) when is_binary(text) and 0 < n do
    graphemes = String.graphemes(text)

    if length(graphemes) == 1 do
      graphemes
    else
      graphemes
      |> Enum.chunk_every(n, 1, :discard)
      |> Enum.map(&Enum.join/1)
    end
  end

  @spec decode(words(), pos_integer()) :: String.t()
  def decode(words, n \\ 2) when is_list(words) and 0 < n do
    case words do
      [] ->
        ""

      [word] ->
        word

      [head | rest] ->
        Enum.reduce(rest, head, fn word, acc ->
          acc <> String.slice(word, (n - 1)..-1)
        end)
    end
  end
end
