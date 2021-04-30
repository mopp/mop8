defmodule Support.TestReplyer do
  use GenServer

  defstruct [:pid]

  def new() do
    {:ok, pid} = start_link()

    %__MODULE__{
      pid: pid
    }
  end

  @spec start_link() :: GenServer.on_start()
  defp start_link() do
    GenServer.start_link(__MODULE__, nil)
  end

  def get_replies(%__MODULE__{pid: pid}) do
    GenServer.call(pid, :get_replies)
  end

  @impl GenServer
  def init(_) do
    {:ok, []}
  end

  @impl GenServer
  def handle_call(:get_replies, _from, replies) do
    {:reply, replies, replies}
  end

  @impl GenServer
  def handle_cast({:send, _channnel_id, text}, replies) do
    {:noreply, [text | replies]}
  end
end

defimpl Mop8.Bot.Replyer, for: Support.TestReplyer do
  alias Support.TestReplyer

  def send(%TestReplyer{pid: pid}, channnel_id, text) do
    GenServer.cast(pid, {:send, channnel_id, text})
  end
end
