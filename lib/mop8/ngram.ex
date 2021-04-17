defmodule Mop8.Ngram do
  @type words() :: [String.t()]

  @spec encode(String.t(), pos_integer()) :: words()
  def encode(input, n \\ 2) do
    if n != 2 do
      raise "not supported yet"
    end

    input
    |> String.graphemes()
    |> bigram([])
    |> Enum.reverse()
  end

  @spec bigram([String.grapheme()], words()) :: words()
  defp bigram([], _) do
    []
  end

  defp bigram([x], acc) do
    [x | acc]
  end

  defp bigram([x, y], acc) do
    [x <> y | acc]
  end

  defp bigram([x | [y | _] = rest], acc) do
    bigram(rest, [x <> y | acc])
  end

  @spec decode(words(), pos_integer()) :: String.t()
  def decode(words, n \\ 2) do
    if n != 2 do
      raise "not supported yet"
    end

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
