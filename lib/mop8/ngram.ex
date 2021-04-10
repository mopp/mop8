defmodule Mop8.Ngram do
  @type words() :: [String.t()]

  @spec bigram(String.t()) :: words()
  def bigram(input) do
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
end
