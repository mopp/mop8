defmodule Mop8.WordMap do
  require Logger

  alias Mop8.Ngram
  alias Mop8.Selector

  @opaque t() :: %{
            (count_map :: String.t()) => %{
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

  @spec put(t(), Ngram.words()) :: t()
  def put(word_map, words) when is_map(word_map) and is_list(words) do
    case words do
      [] ->
        word_map

      [word] ->
        count_map =
          case word_map[word] do
            nil ->
              %{count: 1, next_map: %{}}

            %{count: count} = count_map ->
              Map.put(count_map, :count, count + 1)
          end

        Map.put(word_map, word, count_map)

      [current_word | [next_word | _] = rest] ->
        count_map =
          case word_map[current_word] do
            nil ->
              %{count: 1, next_map: %{next_word => 1}}

            %{
              count: current_count,
              next_map: next_map
            } = count_map ->
              %{
                count_map
                | count: current_count + 1,
                  next_map: Map.update(next_map, next_word, 1, &(&1 + 1))
              }
          end

        word_map
        |> Map.put(current_word, count_map)
        |> put(rest)
    end
  end

  @spec build_sentence(t(), Selector.t()) :: {:ok, Ngram.words()} | {:error, :nothing_to_say}
  def build_sentence(word_map, selector \\ &Selector.roulette/1) when is_map(word_map) do
    # Select the first word.
    result =
      word_map
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

  # TODO: Separate it to infrastructure layer.
  @spec load(Path.t()) :: {:ok, t()} | {:error, reason :: any()}
  def load(filepath) do
    case File.read(Path.expand(filepath)) do
      {:ok, raw} ->
        with {:ok, decoded} <- Poison.decode(raw) do
          word_map =
            Map.new(decoded, fn {key, %{"count" => count, "next_map" => next_map}} ->
              {key, %{count: count, next_map: next_map}}
            end)

          {:ok, word_map}
        end

      {:error, _} = error ->
        error
    end
  end

  # TODO: Separate it to infrastructure layer.
  @spec store(Path.t(), t()) :: :ok | {:error, reason :: any()}
  def store(filepath, word_map) do
    case Poison.encode(word_map) do
      {:ok, raw} ->
        File.write(Path.expand(filepath), raw)

      {:error, _} = error ->
        error
    end
  end
end
