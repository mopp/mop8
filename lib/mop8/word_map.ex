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
  def put(word_map, []) when is_map(word_map) do
    word_map
  end

  def put(word_map, [_]) when is_map(word_map) do
    # FIXME: Handle the shortest sentence.
    word_map
  end

  def put(word_map, [x | [y | _] = rest]) when is_map(word_map) do
    {_, word_map} =
      Map.get_and_update(word_map, x, fn
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

    put(word_map, rest)
  end
end
