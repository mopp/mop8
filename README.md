## Mop8

Slack bot for imitating target user.


## How to run

Store the required environment variable into `.env` file.

```console
export TARGET_CHANNEL_ID="hoge"
export TARGET_USER_ID="fuga"
export BOT_USER_ID="piyo"
export SLACK_APP_LEVEL_TOKEN='xapp-xxx'
export SLACK_BOT_USER_OAUTH_TOKEN='xoxb-xxx'
export MOP8_STORAGE_DIR="/tmp/mop8"
export DRY_RUN="false"
```

```
mix deps.get
mix compile

source .env

iex -S mix
```


## How to test

```console
mix text
mix dialyzer
```
