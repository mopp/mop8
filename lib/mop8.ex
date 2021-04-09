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

  def update_gram_map(gram_map, []) do
    gram_map
  end

  def update_gram_map(gram_map, [_]) do
    gram_map
  end

  def update_gram_map(gram_map, [x | [y | _] = rest]) do
    {_, gram_map} =
      Map.get_and_update(gram_map, x, fn
        nil ->
          {nil, %{y => 1}}

        count_map ->
          Map.get_and_update(count_map, y, fn
            nil ->
              # Initialize.
              {nil, 1}

            v ->
              # Increment the count.
              {v, v + 1}
          end)
      end)

    update_gram_map(gram_map, rest)
  end
end
