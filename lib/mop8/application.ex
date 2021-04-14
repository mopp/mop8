defmodule Mop8.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  alias Mop8.Slack
  use Application

  @impl true
  def start(_type, _args) do
    with {:ok, websocket_url} <- Slack.WebSocket.fetch_url() do
      children = [
        {Slack.Bot, websocket_url}
      ]

      opts = [strategy: :one_for_one, name: Mop8.Supervisor]
      Supervisor.start_link(children, opts)
    else
      {:error, reason} ->
        {:error, {:fetch_endpoint, reason}}
    end
  end
end
