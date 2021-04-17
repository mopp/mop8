defmodule Mop8.Selector do
  def roulette(pairs, dart) when is_list(pairs) and is_integer(dart) do
    Enum.reduce_while(pairs, 0, fn {value, weight}, acc ->
      acc = weight + acc

      if dart <= acc do
        {:halt, value}
      else
        {:cont, acc}
      end
    end)
  end
end
