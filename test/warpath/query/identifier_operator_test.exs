defmodule Warpath.Query.IdentifierOperatorTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Warpath.Element
  alias Warpath.Execution.Env
  alias Warpath.Query.IdentifierOperator

  @relative_path [{:root, "$"}]

  defp env_evaluation_for(propery_name, previous \\ nil) do
    Env.new({:dot, {:property, propery_name}}, previous)
  end

  describe "IdentifierOperator.Map" do
    property "evaluate a existent property always create a element" do
      check all map <- map_of(term(), term(), min_length: 1),
                {key, value} = Enum.random(map) do
        element = Element.new(value, [{:property, key} | @relative_path])

        assert IdentifierOperator.evaluate(map, @relative_path, env_evaluation_for(key)) ==
                 element
      end
    end

    property "evaluate a non existent property always create a element with value nil with empty path" do
      unique = make_ref()

      check all map <- map_of(term(), term(), min_length: 1) do
        element = Element.new(nil, [])

        assert IdentifierOperator.evaluate(map, @relative_path, env_evaluation_for(unique)) ==
                 element
      end
    end
  end

  describe "IdentifierOperator.List" do
    property "evaluate a keyword as document dispatch to Map" do
      check all keyword <-
                  uniq_list_of(
                    {atom(:alphanumeric), term()},
                    min_length: 1,
                    uniq_fun: fn {key, _value} -> key end
                  ),
                {key, value} = Enum.random(keyword) do
        element = Element.new(value, [{:property, key} | @relative_path])
        result = IdentifierOperator.evaluate(keyword, @relative_path, env_evaluation_for(key))

        assert result == element
      end
    end

    test "traverse it's elements and query it value when it's a map" do
      elements_with_map = [
        Element.new(%{"b" => 1}, @relative_path),
        Element.new(%{"a" => 2, "child" => "2"}, @relative_path),
        Element.new(%{"c" => 3, "child" => "3"}, @relative_path),
        Element.new(%{"c" => 4, "child" => "4"}, @relative_path)
      ]

      previous_operation = Env.new({:wildcard, :*})
      env = env_evaluation_for("child", previous_operation)

      expected = [
        Element.new("2", [{:property, "child"} | @relative_path]),
        Element.new("3", [{:property, "child"} | @relative_path]),
        Element.new("4", [{:property, "child"} | @relative_path])
      ]

      assert IdentifierOperator.evaluate(elements_with_map, [], env) == expected
    end

    test "traverse it's elements and query it value when it's a keyword list" do
      elements_with_keyword_list = [
        Element.new([b: 1], @relative_path),
        Element.new([a: 2, child: "2"], @relative_path),
        Element.new([c: 3, child: "3"], @relative_path),
        Element.new([c: 4, child: "4"], @relative_path),
        Element.new(%{c: 5, child: "from map"}, @relative_path)
      ]

      previous_operation = Env.new({:wildcard, :*})
      env = env_evaluation_for(:child, previous_operation)

      expected = [
        Element.new("2", [{:property, :child} | @relative_path]),
        Element.new("3", [{:property, :child} | @relative_path]),
        Element.new("4", [{:property, :child} | @relative_path]),
        Element.new("from map", [{:property, :child} | @relative_path])
      ]

      assert IdentifierOperator.evaluate(elements_with_keyword_list, [], env) == expected
    end

    test "evaluate a empty list always result in element with nil value and empty path" do
      assert IdentifierOperator.evaluate([], @relative_path, env_evaluation_for(:any)) ==
               Element.new(nil, [])
    end
  end

  test "evaluate/3 is nil safe" do
    assert IdentifierOperator.evaluate(nil, @relative_path, env_evaluation_for("propery_name")) ==
             Element.new(nil, [])
  end
end
