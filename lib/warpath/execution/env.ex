defmodule Warpath.Execution.Env do
  alias Warpath.Query.RootOperator
  alias Warpath.Query.IdentifierOperator
  alias Warpath.Query.WildcardOperator
  alias Warpath.Query.DescendantOperator
  alias Warpath.Query.ArrayIndexOperator
  alias Warpath.Query.FilterOperator
  alias Warpath.Query.SliceOperator
  alias Warpath.Query.UnionOperator

  @moduledoc false
  @type operator :: module()
  @type instruction :: Warpath.Expression.token()

  @type t :: %__MODULE__{
          instruction: instruction(),
          operator: operator(),
          previous_operator: operator()
        }

  defstruct operator: nil, instruction: nil, previous_operator: nil

  def new(instruction, previous_operator \\ nil) do
    %__MODULE__{
      operator: operator_for(instruction),
      instruction: instruction,
      previous_operator: previous_operator
    }
  end

  defp operator_for({:root, _}), do: RootOperator
  defp operator_for({:dot, _}), do: IdentifierOperator
  defp operator_for({:wildcard, _}), do: WildcardOperator
  defp operator_for({:scan, _}), do: DescendantOperator
  defp operator_for({:array_indexes, _}), do: ArrayIndexOperator
  defp operator_for({:filter, _}), do: FilterOperator
  defp operator_for({:array_slice, _}), do: SliceOperator
  defp operator_for({:union, _}), do: UnionOperator
end