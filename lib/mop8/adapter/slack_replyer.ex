defmodule Mop8.Adapter.SlackReplyer do
  defstruct []

  @type t :: %__MODULE__{}

  def new() do
    %__MODULE__{}
  end
end

defimpl Mop8.Bot.Replyer, for: Mop8.Adapter.SlackReplyer do
  alias Mop8.Adapter.SlackReplyer

  @spec send(SlackReplyer.t(), String.t(), String.t()) :: :ok | {:error, reason :: any()}
  def send(%SlackReplyer{}, channnel_id, text) do
    with %{"ok" => true} <- Slack.Web.Chat.post_message(channnel_id, text) do
      :ok
    else
      response ->
        {:error, response}
    end
  end
end
