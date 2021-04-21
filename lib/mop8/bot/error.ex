defmodule Mop8.Bot.Error do
  defmodule ConfigError do
    defexception [:message]
  end

  defmodule InvalidMessageError do
    defexception [:message]
  end
end
