defmodule Mop8 do
  @moduledoc """
  Documentation for `Mop8`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Mop8.hello()
      :world

  """
  def hello do
    :world
  end

  def bigram(input) do
    input
    |> String.graphemes()
    |> bigram([])
    |> Enum.reverse()
  end

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
