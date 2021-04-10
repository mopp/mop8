defmodule Mop8.WordMap do
  alias Mop8.Ngram

  @type t() :: %{
          String.t() => count_map()
        }

  @type count_map() :: %{
          required(String.t()) => pos_integer()
        }

  @spec new() :: t()
  def new() do
    %{}
  end

  @spec put(t(), Ngram.words()) :: t()
  def put(word_map, words) when is_map(word_map) do
    case words do
      [] ->
        word_map

      [_] ->
        # FIXME: Handle the shortest sentence.
        word_map

      [current_word | [next_word | _] = rest] ->
        case word_map[current_word] do
          nil ->
            Map.put(word_map, current_word, %{next_word => 1})

          count_map ->
            Map.put(word_map, current_word, count_word(count_map, next_word))
        end
        |> put(rest)
    end
  end

  defp count_word(count_map, word) when is_map(count_map) and is_binary(word) do
    case count_map[word] do
      nil ->
        Map.put(count_map, word, 1)

      count ->
        Map.put(count_map, word, 1 + count)
    end
  end
end
