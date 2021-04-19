defprotocol Mop8.Repo.WordMap do
  alias Mop8.WordMap

  @spec load(t) :: {:ok, {t, WordMap.t()}} | {:error, reason :: any()}
  def load(self)

  @spec store(t, WordMap.t()) :: {:ok, t} | {:error, reason :: any()}
  def store(self, word_map)
end
