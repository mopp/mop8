defmodule Mop8.Sentence do
  alias Mop8.WordMap
  alias Mop8.Ngram
  alias Mop8.Selector

  @spec construct(WordMap.t()) :: {:ok, Ngram.words()} | {:error, :nothing_to_say}
  def construct(word_map) when is_map(word_map) do
    if map_size(word_map) == 0 do
      {:error, :nothing_to_say}
    else
      # Select first word.
      {word, count_map} = Enum.random(word_map)

      sentence =
        word_map
        |> construct(count_map, [word])
        |> Enum.reverse()

      {:ok, sentence}
    end
  end

  defp construct(word_map, count_map, words) do
    result =
      count_map
      |> Map.to_list()
      |> Selector.roulette()

    word =
      case result do
        {:ok, word} ->
          word

        {:error, :no_element} ->
          nil
      end

    case word_map[word] do
      nil ->
        [word | words]

      count_map ->
        construct(word_map, count_map, [word | words])
    end
  end
end
