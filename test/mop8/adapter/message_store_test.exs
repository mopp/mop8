defmodule Mop8.Adapter.MessageStoreTest do
  use ExUnit.Case

  alias Mop8.Adapter.MessageStore
  alias Mop8.Bot.Message
  alias Mop8.Bot.Repo

  @tag :tmp_dir
  test "insert/2 and all/1 stores the given message and loads the all messages", %{
    tmp_dir: tmp_dir
  } do
    System.put_env("MOP8_STORAGE_DIR", tmp_dir)
    store = MessageStore.new()

    message1 = Message.new("test_user_id", "hi", ~U[2021-04-19 22:12:00Z])
    assert {:ok, store} = Repo.Message.insert(store, message1)

    message2 = Message.new("test_user_id", "yo", ~U[2021-04-19 23:00:00Z])
    assert {:ok, store} = Repo.Message.insert(store, message2)

    messages = [message2, message1]
    assert {:ok, {%MessageStore{messages: ^messages}, ^messages}} = Repo.Message.all(store)
  end
end
