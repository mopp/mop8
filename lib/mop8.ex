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

  def construct_sentence(gram_map) do
    {word, count_map} = Enum.random(gram_map)
    construct_sentence(gram_map, count_map, word)
  end

  defp construct_sentence(gram_map, count_map, sentence) do
    # Do roulette selection
    # NOTE: Introduce cache for maximum value if the performance gets slow down.
    selector =
      Map.values(count_map)
      |> Enum.sum()
      |> :rand.uniform()

    word =
      count_map
      |> Map.to_list()
      |> do_roulette_selection(selector)

    case gram_map[word] do
      nil ->
        append_ngram_word(sentence, word)

      count_map ->
        construct_sentence(gram_map, count_map, append_ngram_word(sentence, word))
    end
  end

  defp append_ngram_word(sentence, word, n \\ 2) do
    sentence <> String.slice(word, (n - 1)..-1)
  end

  # FIXME: Create module.
  def do_roulette_selection(pairs, dart) when is_list(pairs) and is_integer(dart) do
    Enum.reduce_while(pairs, 0, fn {value, weight}, acc ->
      acc = weight + acc

      if dart <= acc do
        {:halt, value}
      else
        {:cont, acc}
      end
    end)
  end
end
