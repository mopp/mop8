defmodule Mop8.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  alias Mop8.Slack

  @impl true
  def start(_type, _args) do
    Logger.info("Start application.")

    Application.put_env(:slack, :api_token, System.fetch_env!("SLACK_BOT_USER_OAUTH_TOKEN"))

    children = [
      {Slack.Worker, nil},
      {Slack.SocketMode.Client, nil}
    ]

    opts = [strategy: :one_for_one, name: Mop8.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
