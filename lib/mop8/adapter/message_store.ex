defmodule Mop8.Adapter.MessageStore do
  alias Mop8.Bot.Message

  @enforce_keys [:filepath, :messages]

  defstruct [:filepath, :messages]

  @opaque t :: %__MODULE__{
            filepath: Path.t(),
            messages: [Message.t()]
          }

  @spec new(Path.t()) :: t()
  def new(filepath) do
    %__MODULE__{
      filepath: filepath,
      messages: []
    }
  end
end

defimpl Mop8.Bot.Repo.Message, for: Mop8.Adapter.MessageStore do
  alias Mop8.Adapter.MessageStore
  alias Mop8.Bot.Message
  alias Mop8.Bot.Repo

  @spec all(Repo.Message.t()) ::
          {:ok, {MessageStore.t(), [Message.t()]}} | {:error, reason :: any()}
  def all(%MessageStore{filepath: filepath} = store) do
    with {:ok, raw_json} <- File.read(filepath),
         {:ok, raw_messages} <- Poison.decode(raw_json, keys: :atoms!),
         {:ok, raw_messages} <- validate_raw_messages(raw_messages) do
      # :user_id is just for creating atom for Poison.
      messages =
        raw_messages
        |> Enum.map(fn %{event_at: event_at, user_id: _user_id} = raw_message ->
          {:ok, event_at, _} = DateTime.from_iso8601(event_at)
          struct(Message, %{raw_message | event_at: event_at})
        end)

      # TODO: Do validation.
      {:ok, {%{store | messages: messages}, messages}}
    else
      {:error, :enoent} ->
        {:ok, {store, []}}

      error ->
        error
    end
  end

  defp validate_raw_messages(raw_messages) do
    if is_list(raw_messages) do
      {:ok, raw_messages}
    else
      {:error, :invalid_data_stored}
    end
  end

  @spec insert(Repo.Message.t(), Message.t()) ::
          {:ok, MessageStore.t()} | {:error, reason :: any()}
  def insert(%MessageStore{filepath: filepath, messages: messages} = store, message) do
    # TODO: Do validation.
    messages = [message | messages]

    with {:ok, raw_json} <- Poison.encode(messages),
         :ok <- File.write(filepath, raw_json) do
      {:ok, %{store | messages: messages}}
    end
  end
end
