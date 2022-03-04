defmodule Mop8.Bot.PersonaTest do
  use ExUnit.Case, async: true

  alias Mop8.Adapter.MessageStore
  alias Mop8.Adapter.WordMapStore
  alias Mop8.Bot.Repo
  alias Mop8.Bot.Config
  alias Mop8.Bot.Message
  alias Mop8.Bot.Persona
  alias Mop8.Bot.Brain
  alias Support.TestReplyer

  describe "process_message/2" do
    @describetag :tmp_dir

    setup :prepare

    test "creates empty reply when it receives mention and the WordMap is empty", %{
      test_replyer: test_replyer
    } do
      message = Message.new("<@test_bot_id> hi", ~U[2021-04-30 22:12:00Z])

      assert :ok = Persona.talk(message, "hoge", "test_channel_id")

      assert ["NO DATA"] = TestReplyer.get_replies(test_replyer)
    end

    test "creates reply when it receives mention", %{test_replyer: test_replyer} do
      message = Message.new("<@test_bot_id> hi", ~U[2021-04-30 22:12:00Z])

      assert :ok = Persona.talk(message, "test_target_user_id", "test_channel_id")

      assert ["hi"] = TestReplyer.get_replies(test_replyer)
    end
  end

  describe "reconstruct/0" do
    @describetag :tmp_dir

    setup context do
      result = prepare(context)

      :ok =
        Message.new("<@test_bot_id> hi", ~U[2021-04-30 22:12:00Z])
        |> Persona.talk("test_target_user_id", "test_channel_id")

      :ok =
        Message.new("<@test_bot_id> hi", ~U[2021-04-30 22:12:00Z])
        |> Persona.talk("test_target_user_id", "test_channel_id")

      result
    end

    test "reconstructs the WordMap from the stored messages", %{
      word_map_store: word_map_store
    } do
      # Delete the WordMap.
      Repo.WordMap.store(word_map_store, Brain.Ngram.WordMap.new())

      assert :ok = Persona.reconstruct()

      {:ok, {_, word_map}} = Repo.WordMap.load(word_map_store)
      assert false == Enum.empty?(word_map)
    end
  end

  defp prepare(%{tmp_dir: tmp_dir}) do
    word_map_store =
      WordMapStore.new(
        [tmp_dir, "word_map.json"]
        |> Path.join()
        |> Path.expand()
      )

    start_supervised!({
      Brain.Ngram,
      %{
        word_map_store: word_map_store,
        seed: {321, 88, 67}
      }
    })

    test_replyer = TestReplyer.new()

    start_supervised!({
      Persona,
      {
        Config.new(
          "test_target_user_id",
          "test_bot_id"
        ),
        MessageStore.new(
          [tmp_dir, "messages.json"]
          |> Path.join()
          |> Path.expand()
        ),
        test_replyer
      }
    })

    {:ok, test_replyer: test_replyer, word_map_store: word_map_store}
  end
end
