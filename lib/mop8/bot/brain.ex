defmodule Mop8.Bot.Brain do
  alias Mop8.Bot.Message

  @spec learn(Message.t()) :: :ok | {:error, reason :: any()}
  def learn(message) when is_struct(message, Message) do
    GenServer.call(__MODULE__, {:learn, message})
  end

  @spec reply(hint :: any()) :: {:ok, String.t()} | {:error, reason :: any() | :nothing_to_say}
  def reply(hint) do
    GenServer.call(__MODULE__, {:reply, hint})
  end

  @spec relearn([Message.t()]) :: :ok | {:error, reason :: any()}
  def relearn(messages) when is_list(messages) do
    GenServer.call(__MODULE__, {:relearn, messages})
  end
end
