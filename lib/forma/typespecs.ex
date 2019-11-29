defmodule Forma.Typespecs do
  def compile(module) do
    module
    |> Kernel.Typespec.beam_types()
    |> rewrite(module)
    |> Enum.map(fn {t, d} -> {{module, t}, d} end)
    |> Enum.into(%{})
  end

  # [{:type, _}, {:type, _}]
  def rewrite([x | xs], module) do
    [rewrite(x, module) | rewrite(xs, module)]
  end

  #           {:opaque, {:t, {}, [{:var, 37, :value}]}}
  def rewrite({:opaque, {name, _, _}}, _module) do
    {name, :opaque}
  end

  def rewrite({:type, {name, tree, _}}, module) do
    {name, rewrite(tree, module)}
  end

  #          {:type, {:t, {:user_type, 38, :t, [{:type, 38, :term, []}]}, []}}, [] 
  def rewrite({:type, {name, type}}, module) do
    {name, rewrite(type, module)}
  end

  #         {:type, 149, :map, tree}
  def rewrite({:type, _, :map, [{:type, _, :map_field_assoc, [key, value]} | _]}, module) do
    {:assoc_map, {rewrite(key, module), rewrite(value, module)}}
  end

  def rewrite({:type, _, :map, [{:type, _, :map_field_exact, type} | _] = tree}, module) do
    case type do
      [{:atom, _, :__struct__}, {:atom, _, struct_name}] ->
        {:struct, struct_name, parse_struct(tree, module)}

      [{:atom, _, _}, _] ->
        {:exact_map, map(tree, module)}

      [key, value] ->
        {:exact_map, {rewrite(key, module), rewrite(value, module)}}
    end
  end

  def rewrite({:user_type, _, name, args}, module), do: {{module, name}, rewrite(args, module)}
  def rewrite({:remote_type, _, [{:atom, _, remote_module}, {:atom, _, type}, args]}, module), do: {{remote_module, type}, rewrite(args, module)}
  def rewrite({:type, _, :union, tree}, module), do: {:union, Enum.map(tree, &rewrite(&1, module))}
  def rewrite({:type, _, :list, [tree | []]}, module), do: {:list, rewrite(tree, module)}
  def rewrite({:atom, _, val}, _module), do: {:atom, val}

  # scalar types default to their type.
  def rewrite({:type, _, typ, tree}, _module), do: {typ, tree}
  def rewrite(x, _module), do: x

  def rewrite([], _, _module) do
    []
  end

  def struct_name([{:type, _, :map_field_exact, [{:atom, _, :__struct__}, {:atom, _, struct}]} | _]), do: struct
  def struct_name(_), do: nil

  def parse_struct([{:type, _, :map_field_exact, [{:atom, _, :__struct__}, {:atom, _, _}]} | rest], module), do: map(rest, module)

  def map(tree, module) do
    map(tree, module, %{})
  end

  #       [{:type, 278, :map_field_exact, [{:atom, 0, :atom}, {:type, 285, :atom, []}]}
  def map([{:type,   _, :map_field_exact, [{field_type, _,  name},                     typ]} | rest], module, acc) do
    field = case field_type do
      :atom -> name
      _ -> to_string(name)
    end
    acc = Map.put(acc, to_string(name), {field, rewrite(typ, module)})
    map(rest, module, acc)
  end

  def map([], _module, acc) do
    acc
  end
end
