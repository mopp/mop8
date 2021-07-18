defmodule Mop8.Bot.WordMap do
  require Logger

  alias Mop8.Bot.Ngram
  alias Mop8.Bot.Selector

  @opaque t() :: %{
            (count_map :: String.t()) => %{
              required(:is_head) => boolean(),
              required(:is_tail) => boolean(),
              required(:count) => pos_integer(),
              required(:next_map) => %{
                String.t() => pos_integer()
              }
            }
          }

  @spec new() :: t()
  def new() do
    %{}
  end

  @spec put(t(), Ngram.words(), boolean()) :: t()
  def put(word_map, words, is_head \\ true) when is_map(word_map) and is_list(words) do
    case words do
      [] ->
        word_map

      [word] ->
        count_map =
          case word_map[word] do
            nil ->
              %{count: 1, next_map: %{}, is_head: is_head, is_tail: true}

            %{count: count} = count_map ->
              Map.put(count_map, :count, count + 1)
          end

        Map.put(word_map, word, count_map)

      [current_word | [next_word | _] = rest] ->
        count_map =
          case word_map[current_word] do
            nil ->
              %{
                count: 1,
                next_map: %{next_word => 1},
                is_head: is_head,
                is_tail: false
              }

            %{
              count: current_count,
              next_map: next_map
            } = count_map ->
              %{
                count_map
                | count: current_count + 1,
                  next_map: Map.update(next_map, next_word, 1, &(&1 + 1)),
                  is_head: is_head,
                  is_tail: false
              }
          end

        word_map
        |> Map.put(current_word, count_map)
        |> put(rest, false)
    end
  end

  @spec build_sentence(t(), Selector.t()) :: {:ok, Ngram.words()} | {:error, :nothing_to_say}
  def build_sentence(word_map, selector \\ &Selector.roulette/1) when is_map(word_map) do
    # Select the first word.
    result =
      word_map
      |> Enum.filter(fn {_, %{is_head: is_head}} -> is_head end)
      |> Enum.map(fn {word, %{count: count}} -> {word, count} end)
      |> selector.()

    case result do
      {:ok, word} ->
        sentence =
          word_map
          |> build_sentence(word_map[word][:next_map], selector, [word])
          |> Enum.reverse()

        {:ok, sentence}

      {:error, :no_element} ->
        {:error, :nothing_to_say}
    end
  end

  defp build_sentence(word_map, next_map, selector, words) do
    # f(x) = (2^x - 1.0) / 7.0
    # 0.0 <= x <= 3.0
    # 0.0 <= f(x) <= 1.0
    x = length(words) * 0.05
    break_probability = (:math.pow(2, x) - 1.0) / 7.0

    if :rand.uniform_real() < break_probability || next_map[:is_tail] do
      # Break building sentence.
      words
    else
      # Select the next word.
      result =
        next_map
        |> Map.to_list()
        |> selector.()

      case result do
        {:ok, word} ->
          case word_map[word] do
            nil ->
              info = %{
                word_map: word_map,
                next_map: next_map,
                words: words
              }

              raise "Bug: WordMap.put/2 may have a bug: #{inspect(info)}"

            %{next_map: next_map} ->
              build_sentence(word_map, next_map, selector, [word | words])
          end

        {:error, :no_element} ->
          # The word is terminal.
          words
      end
    end
  end
end
