defmodule Mop8.Adapter.ConsoleReplyer do
  defstruct []

  @type t :: %__MODULE__{}

  def new() do
    %__MODULE__{}
  end
end

defimpl Mop8.Bot.Replyer, for: Mop8.Adapter.ConsoleReplyer do
  require Logger

  alias Mop8.Adapter.ConsoleReplyer

  @spec send(ConsoleReplyer.t(), String.t(), String.t()) :: :ok
  def send(%ConsoleReplyer{}, channnel_id, text) do
    Logger.info("Reply: <#{text}> at #{channnel_id}")

    :ok
  end
end
