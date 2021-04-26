defmodule Mop8.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  alias Mop8.Adapter.MessageController
  alias Mop8.Adapter.MessageStore
  alias Mop8.Adapter.Slack
  alias Mop8.Adapter.WordMapStore
  alias Mop8.Bot

  @impl true
  def start(_type, _args) do
    Logger.info("Start application.")

    Application.put_env(:slack, :api_token, System.fetch_env!("SLACK_BOT_USER_OAUTH_TOKEN"))

    processor =
      Bot.Processor.new(
        Bot.Config.new(
          System.fetch_env!("TARGET_USER_ID"),
          System.fetch_env!("BOT_USER_ID")
        ),
        WordMapStore.new(),
        MessageStore.new()
      )

    children = [
      {Slack.SocketMode.Client, nil},
      {MessageController, processor}
    ]

    opts = [strategy: :one_for_one, name: Mop8.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
