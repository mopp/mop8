defprotocol Mop8.Bot.Repo.WordMap do
  alias Mop8.Bot.WordMap

  @spec load(t) :: {:ok, {t, WordMap.t()}} | {:error, reason :: any()}
  def load(self)

  @spec store(t, WordMap.t()) :: {:ok, t} | {:error, reason :: any()}
  def store(self, word_map)
end
