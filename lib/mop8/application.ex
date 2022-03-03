defmodule Mop8.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  require Logger

  alias Mop8.Adapter.ConsoleReplyer
  alias Mop8.Adapter.MessageController
  alias Mop8.Adapter.MessageStore
  alias Mop8.Adapter.Slack
  alias Mop8.Adapter.SlackReplyer
  alias Mop8.Adapter.WordMapStore
  alias Mop8.Bot
  alias Mop8.Maintainer

  @impl true
  def start(_type, _args) do
    Logger.info("Start application.")

    Application.put_env(:slack, :api_token, System.fetch_env!("SLACK_BOT_USER_OAUTH_TOKEN"))

    storage_dir = System.fetch_env!("MOP8_STORAGE_DIR")

    target_user_id = System.fetch_env!("TARGET_USER_ID")
    target_channel_id = System.fetch_env!("TARGET_CHANNEL_ID")

    # TODO: Add exlusive control.
    message_store =
      MessageStore.new(
        [storage_dir, "messages.json"]
        |> Path.join()
        |> Path.expand()
      )

    word_map_store =
      WordMapStore.new(
        [storage_dir, "word_map.json"]
        |> Path.join()
        |> Path.expand()
      )

    persona =
      Bot.Persona.new(
        Bot.Config.new(
          target_user_id,
          System.fetch_env!("BOT_USER_ID")
        ),
        word_map_store,
        message_store,
        if System.get_env("DRY_RUN", "true") == "true" do
          ConsoleReplyer.new()
        else
          SlackReplyer.new()
        end
      )

    children = [
      {Slack.SocketMode.Client, System.fetch_env!("SLACK_APP_LEVEL_TOKEN")},
      {MessageController, persona},
      {Maintainer, {target_user_id, target_channel_id, message_store, word_map_store}}
    ]

    opts = [strategy: :one_for_one, name: Mop8.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
