defmodule Fragments do
  for {name, val} <- [one: 1, two: 2, three: 3] do
    def unquote(name)(), do: unquote(val)
  end
end
