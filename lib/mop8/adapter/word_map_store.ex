defmodule Mop8.Adapter.WordMapStore do
  alias Mop8.Bot.Brain.Ngram.WordMap

  @enforce_keys [:filepath, :word_map]

  defstruct [:filepath, :word_map]

  @opaque t :: %__MODULE__{
            filepath: Path.t(),
            word_map: nil | WordMap.t()
          }

  @spec new(Path.t()) :: t()
  def new(filepath) do
    %__MODULE__{
      filepath: filepath,
      word_map: nil
    }
  end
end

defimpl Mop8.Bot.Repo.WordMap, for: Mop8.Adapter.WordMapStore do
  alias Mop8.Adapter.WordMapStore
  alias Mop8.Bot.Repo
  alias Mop8.Bot.Brain.Ngram.WordMap

  @spec load(Repo.WordMap.t()) ::
          {:ok, {Repo.WordMap.t(), WordMap.t()}} | {:error, reason :: any()}
  def load(store) do
    case store do
      %WordMapStore{word_map: nil, filepath: filepath} ->
        with {:ok, word_map} <- load_from_file(filepath) do
          {:ok, {%{store | word_map: word_map}, word_map}}
        end

      %WordMapStore{word_map: word_map} ->
        {:ok, {store, word_map}}
    end
  end

  def load_from_file(filepath) do
    with {:ok, raw_json} <- File.read(filepath),
         {:ok, raw_word_map} <- Poison.decode(raw_json) do
      word_map =
        Map.new(raw_word_map, fn {key, stat} ->
          {key, Map.new(stat, fn {k, v} -> {String.to_atom(k), v} end)}
        end)

      {:ok, word_map}
    else
      {:error, :enoent} ->
        {:ok, WordMap.new()}

      error ->
        error
    end
  end

  @spec store(Repo.WordMap.t(), WordMap.t()) ::
          {:ok, Repo.WordMap.t()} | {:error, reason :: any()}
  def store(%WordMapStore{filepath: filepath} = store, word_map) do
    with {:ok, raw_json} = Poison.encode(word_map),
         :ok <- File.write(Path.expand(filepath), raw_json) do
      {:ok, %{store | word_map: word_map}}
    end
  end
end
