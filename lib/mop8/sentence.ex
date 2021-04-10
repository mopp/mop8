defmodule Mop8.Sentence do
  alias Mop8.WordMap

  @spec construct(WordMap.t()) :: String.t()
  def construct(word_map) do
    {word, count_map} = Enum.random(word_map)
    construct(word_map, count_map, word)
  end

  defp construct(word_map, count_map, sentence) do
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

    case word_map[word] do
      nil ->
        append_ngram_word(sentence, word)

      count_map ->
        construct(word_map, count_map, append_ngram_word(sentence, word))
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
