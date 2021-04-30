defprotocol Mop8.Bot.Replyer do
  @spec send(t(), String.t(), String.t()) :: :ok | {:error, reason :: any()}
  def send(replyer, channel_id, text)
end
