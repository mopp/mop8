defmodule Mop8.Sentence do
  alias Mop8.WordMap
  alias Mop8.Ngram
  alias Mop8.Selector

  @spec construct(WordMap.t()) :: Ngram.words()
  def construct(word_map) do
    {word, count_map} = Enum.random(word_map)

    construct(word_map, count_map, [word])
    |> Enum.reverse()
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
