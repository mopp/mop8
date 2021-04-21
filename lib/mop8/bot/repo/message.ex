defprotocol Mop8.Bot.Repo.Message do
  alias Mop8.Bot.Message

  @spec all(t) :: {:ok, {t, [Message.t()]}} | {:error, reason :: any()}
  def all(self)

  @spec insert(t, Message.t()) :: {:ok, t} | {:error, reason :: any()}
  def insert(self, message)
end
