defmodule Mop8.Slack.WebSocket do
  def fetch_url do
    HTTPoison.start()

    url = "https://slack.com/api/apps.connections.open"

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Authorization", "Bearer #{System.fetch_env!("SLACK_APP_LEVEL_TOKEN")}"}
    ]

    with {:ok, response} <- HTTPoison.post(url, "", headers),
         200 <- response.status_code,
         {:ok, slack_response} <- Poison.decode(response.body) do
      case slack_response do
        %{"ok" => true, "url" => websocket_url} ->
          {:ok, websocket_url}

        %{"ok" => false, "error" => reason} ->
          {:error, reason}
      end
    else
      error ->
        error
    end
  end
end
