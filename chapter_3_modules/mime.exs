defmodule Mime do
  #
  # Letting elixir know we're using an external resource
  # This will make Mix recompile our file whenever
  # the resource dependency is changed
  #
  @external_resource mimes_path = Path.join([__DIR__, "mimes.txt"])

  for line <- File.stream!(mimes_path, [], :line) do
    [type | extensions] = line |> String.split(" ") |> Enum.map(&String.trim(&1))

    def exts_from_type(unquote(type)), do: unquote(extensions)
    def type_from_ext(ext) when ext in unquote(extensions), do: unquote(type)
  end

  defmacro __using__(opts) do
    functions_ast = for {type, extensions} <- opts do
      quote do
        def exts_from_type(unquote(type)), do: unquote(extensions)
        def type_from_ext(ext) when ext in unquote(extensions), do: unquote(type)
      end
    end

    IO.puts Macro.to_string(functions_ast)
    quote do
      unquote(functions_ast)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def exts_from_type(_type), do: []
      def type_from_ext(_ext), do: nil
      def valid_type?(type), do: exts_from_type(type) |> Enum.any?
    end
  end
end
