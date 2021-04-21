defmodule Mop8.Bot.Selector do
  @type value :: any()
  @type weight :: pos_integer()
  @type element :: {value(), weight()}
  @type random_func() :: (pos_integer() -> pos_integer())
  @type t :: ([element()] -> {:ok, element()} | {:error, :no_element})

  @spec roulette([element()], random_func()) :: {:ok, element()} | {:error, :no_element}
  def roulette(elements, rand \\ &:rand.uniform/1)

  def roulette([], _) do
    {:error, :no_element}
  end

  def roulette(elements, rand) when is_list(elements) and is_function(rand, 1) do
    total_weight =
      Enum.reduce(elements, 0, fn {_, weight}, acc ->
        weight + acc
      end)

    # NOTE: This random number generator must return positive integer in [1, total_weight].
    dart = rand.(total_weight)

    result =
      Enum.reduce_while(elements, 0, fn {value, weight}, acc ->
        acc = weight + acc

        if dart <= acc do
          {:halt, {:ok, value}}
        else
          {:cont, acc}
        end
      end)

    if is_tuple(result) do
      result
    else
      info = %{
        total_weight: total_weight,
        dart: dart,
        result: result
      }

      raise "Bug: The random number generator might return invalid number. #{inspect(info)}"
    end
  end
end
