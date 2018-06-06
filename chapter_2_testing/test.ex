defmodule Assertion do
  defmacro assert({operator, _, [lhs, rhs]}) do
    quote bind_quoted: [operator: operator, lhs: lhs, rhs: rhs] do
      Assertion.Test.assert(operator, lhs, rhs)
    end
  end
  defmacro assert(:true), do: Assertion.Test.assert_true(true)
  defmacro assert(_), do: Assertion.Test.assert_true(false)

  defmacro refute(:false), do: Assertion.Test.assert_false(false)
  defmacro refute(_), do: Assertion.Test.assert_false(true)

  defmacro __using__(_options) do
    quote do
      import unquote(__MODULE__)
      Module.register_attribute __MODULE__, :tests, accumulate: true
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro test(description, do: test_block) do
    test_func = String.to_atom(description)
    quote do
      @tests {unquote(test_func), unquote(description)}
      def unquote(test_func)(), do: unquote(test_block)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def run, do: Assertion.Test.run(@tests, __MODULE__)
    end
  end
end

defmodule Assertion.Test do
  def run(tests, module) do
    time_elapsed = Enum.map(tests, fn {test_func, description} ->
      Task.async(fn ->
        {time, result} = :timer.tc(module, test_func, [])
        {time, result, description}
      end)
    end)
    |> Task.yield_many
    |> Enum.map(fn {task, result} ->
        result || Task.shutdown(task, :brutal_kill)
    end)
    |> Enum.filter(fn {r, _} -> r == :ok end)
    |> Enum.map(fn {:ok, result} -> result end)
    |> Enum.reduce(0, fn {time, result, description}, acc ->
      case result do
        :ok ->
          out = IO.ANSI.format([:green, :bright, "."], true)
          IO.write out
        {:fail, reason} ->
          IO.puts "\n=================================================="
          IO.ANSI.format([:red, :bright, "FAILURE: #{description}"], true) |> IO.puts
          IO.puts "=================================================="
          IO.puts reason
      end
      acc + time
    end)
    IO.puts "Time for test suit: #{time_elapsed / 1000}ms"
  end

  def assert(:==, lhs, rhs) when lhs == rhs do
    :ok
  end
  def assert(:==, lhs, rhs) do
    {:fail,  """
    FAILURE:
      Expected:      #{lhs}
      to be equal to #{rhs}
    """}
  end
  def assert(:>, lhs, rhs) when lhs > rhs do
    :ok
  end
  def assert(:>, lhs, rhs) do
    {:fail, """
    FAILURE:
      Expected:          #{lhs}
      to be greater then #{rhs}
    """}
  end
  def assert(:<, lhs, rhs) when lhs < rhs do
    :ok
  end
  def assert(:<, lhs, rhs) do
    {:fail, """
    FAILURE:
      Expected:       #{lhs}
      to be less then #{rhs}
    """}
  end

  def assert_true(:true), do: :ok
  def assert_true(_), do: {:fail, """
  FAILURE:
    Expected: #{true}
    Got: #{false}
  """}

  def assert_false(:false), do: :ok
  def assert_false(_), do: {:fail, """
  FAILURE:
    Expected: #{false}
    Got: #{true}
  """}
end

defmodule MathTest do
  use Assertion

  test "integers can be added and subtracted" do
    assert 1 + 1 == 2
    assert 2 + 3 == 5
    assert 5 - 5 == 10
  end

  test "integers can be multiplied and divided" do
     assert 5 * 5 == 25
     assert 10 / 2 == 5
  end

  test "integers can be compared" do
    assert 3 < 6
    assert 5 > 3
  end

  test "asserting true passes" do
    assert true
  end

  test "refuting false passes" do
    refute false
  end

  test "test suit is run async" do
    Process.sleep(500)
    assert true
  end
end
