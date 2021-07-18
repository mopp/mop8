defmodule Mop8.Bot.WordMap do
  require Logger

  alias Mop8.Bot.Ngram
  alias Mop8.Bot.Selector

  @opaque t() :: %{
            String.t() => %{
              heads: pos_integer(),
              tails: pos_integer(),
              count: pos_integer(),
              nexts: [String.t()]
            }
          }

  @spec new() :: t()
  def new() do
    %{}
  end

  @spec put(t(), Ngram.words()) :: t()
  def put(word_map, words) when is_map(word_map) and is_list(words) do
    put(word_map, words, true)
  end

  defp put(word_map, words, is_head) do
    case words do
      [] ->
        word_map

      [word] ->
        word_map
        |> update_by(word, fn
          nil when is_head ->
            %{heads: 1, tails: 1, count: 1, nexts: []}

          nil ->
            %{heads: 0, tails: 1, count: 1, nexts: []}

          %{heads: heads, tails: tails, count: count} = stat when is_head ->
            %{stat | heads: heads + 1, tails: tails + 1, count: count + 1}

          %{tails: tails, count: count} = stat ->
            %{stat | tails: tails + 1, count: count + 1}
        end)

      [word | [next_word | _] = rest] ->
        word_map
        |> update_by(word, fn
          nil when is_head ->
            %{heads: 1, tails: 0, count: 1, nexts: [next_word]}

          nil ->
            %{heads: 0, tails: 0, count: 1, nexts: [next_word]}

          %{heads: heads, count: count, nexts: nexts} = stat when is_head ->
            %{stat | heads: heads + 1, count: count + 1, nexts: Enum.uniq([next_word | nexts])}

          %{count: count, nexts: nexts} = stat ->
            %{stat | count: count + 1, nexts: Enum.uniq([next_word | nexts])}
        end)
        |> put(rest, false)
    end
  end

  defp update_by(map, key, f) do
    Map.put(map, key, f.(map[key]))
  end

  @spec build_sentence(t(), Selector.t()) :: {:ok, Ngram.words()} | {:error, :nothing_to_say}
  def build_sentence(word_map, selector \\ &Selector.roulette/1) when is_map(word_map) do
    with {:ok, word} <- select_first_word(word_map, selector) do
      {:ok, build_sentence(word_map, selector, [word])}
    else
      {:error, :no_element} ->
        {:error, :nothing_to_say}
    end
  end

  def select_first_word(map, selector) do
    map
    |> Enum.filter(fn {_, %{heads: count}} -> count != 0 end)
    |> Enum.map(fn {word, %{heads: count}} -> {word, count} end)
    |> selector.()
  end

  defp build_sentence(word_map, selector, [head | _] = acc) do
    if terminate?(word_map[head]) do
      Enum.reverse(acc)
    else
      {:ok, word} =
        Map.take(word_map, word_map[head][:nexts])
        |> Enum.map(fn {word, %{count: count}} -> {word, count} end)
        |> selector.()

      build_sentence(word_map, selector, [word | acc])
    end
  end

  defp terminate?(%{tails: tails, count: count}) do
    # 0 <= uniform_real < 1
    # always false if tails == 0
    # always true if tails == count
    :rand.uniform_real() < tails / count
  end
end
