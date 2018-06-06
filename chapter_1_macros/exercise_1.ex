defmodule M do
  defmacro define_ast(func_atom, do: ast) do
    {:def, [context: Elixir, import: Kernel],
      [{func_atom, [context: Elixir], Elixir}, [do: ast]]
    }
  end

  defmacro unless(expression, do: block) do
    quote do
      cond do
        !unquote(expression) -> unquote(block)
        
      end
    end
  end
end
