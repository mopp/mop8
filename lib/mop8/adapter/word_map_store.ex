defmodule Mop8.Adapter.WordMapStore do
  alias Mop8.Bot.WordMap

  @enforce_keys [:filepath]

  defstruct [:filepath]

  @opaque t :: %__MODULE__{
            filepath: Path.t()
          }

  @spec new(Path.t()) :: t()
  def new(filepath) do
    %__MODULE__{
      filepath: filepath
    }
  end
end

defimpl Mop8.Bot.Repo.WordMap, for: Mop8.Adapter.WordMapStore do
  alias Mop8.Adapter.WordMapStore
  alias Mop8.Bot.Repo
  alias Mop8.Bot.WordMap

  @spec load(Repo.WordMap.t()) ::
          {:ok, {Repo.WordMap.t(), WordMap.t()}} | {:error, reason :: any()}
  def load(%WordMapStore{filepath: filepath} = store) do
    with {:ok, raw_json} <- File.read(filepath),
         {:ok, raw_word_map} <- Poison.decode(raw_json) do
      word_map =
        Map.new(raw_word_map, fn {key, %{"count" => count, "next_map" => next_map}} ->
          {key, %{count: count, next_map: next_map}}
        end)

      {:ok, {store, word_map}}
    else
      {:error, :enoent} ->
        {:ok, {store, WordMap.new()}}

      error ->
        error
    end
  end

  @spec store(Repo.WordMap.t(), WordMap.t()) ::
          {:ok, Repo.WordMap.t()} | {:error, reason :: any()}
  def store(%WordMapStore{filepath: filepath} = store, word_map) do
    with {:ok, raw_json} = Poison.encode(word_map),
         :ok <- File.write(Path.expand(filepath), raw_json) do
      {:ok, store}
    end
  end
end
