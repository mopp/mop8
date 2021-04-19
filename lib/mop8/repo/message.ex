defprotocol Mop8.Repo.Message do
  alias Mop8.Message

  @spec all(t) :: {:ok, {t, [Message.t()]}} | {:error, reason :: any()}
  def all(self)

  @spec insert(t, Message.t()) :: {:ok, t} | {:error, reason :: any()}
  def insert(self, message)
end
