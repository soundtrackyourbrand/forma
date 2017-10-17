defmodule Forma.Parser do
  def parse!(input, parsers, {:struct, name, fields}) do
    case input do
      input when is_map(input) -> map_exact_fields!(input, parsers, struct(name), fields)
      _ -> raise "not a map #{inspect input}"
    end
  end

  def parse!(input, parsers, {:exact_map, fields}) do
    case input do
      input when is_map(input) -> map_exact_fields!(input, parsers, %{}, fields)
      _ -> raise "not a map #{inspect input}"
    end
  end

  def parse!(input, parsers, {:assoc_map, fields}) do
    case input do
      input when is_map(input) -> map_assoc_fields!(input, parsers, %{}, fields)
      _ -> raise "not a map #{inspect input}"
    end
  end

  def parse!(input, parsers, {:union, possible}) do
    ret = Enum.find_value(possible, fn candidate ->
      try do
        parse!(input, parsers, candidate)
      rescue
        _ -> nil
      end
    end)

    case ret do
      nil -> raise "#{inspect input} doesn't match any of: #{inspect possible}"
      x -> x
    end
  end

  def parse!(input, parsers, {:range, [{type, _, from}, {_, _, to}]}) do
    input = parse!(input, parsers, {type, []})
    case from <= input && input <= to do
      true -> input
      _ -> raise "#{input} is not between #{from} and #{to}"
    end
  end

  def parse!(input, parsers, {:list, type}) do
    case input do
      xs when is_list(xs) -> Enum.map(xs, &parse!(&1, parsers, type))
      x -> raise "can't convert #{inspect x} to a list"
    end
  end

  def parse!(input, _parsers, {:binary, []}) do
    case input do
      x when is_binary(x) -> x
      x -> raise "can't convert #{inspect x} to binary"
    end
  end

  def parse!(input, _parsers, {:integer, []}) do
    case input do
      x when is_number(x) -> trunc(x)
      x -> raise "can't convert #{inspect x} to an integer"
    end
  end

  def parse!(input, _parsers, {:neg_integer, []}) do
    case input do
      x when is_number(x) and x < 0 -> trunc(x)
      x -> raise "can't convert #{inspect x} to a negative integer"
    end
  end

  def parse!(input, _parsers, {:non_neg_integer, []}) do
    case input do
      x when is_number(x) and x > -1 -> trunc(x)
      x -> raise "can't convert #{inspect x} to a non-negative integer"
    end
  end

  def parse!(input, _parsers, {:pos_integer, []}) do
    case input do
      x when is_number(x) and x > 0 -> trunc(x)
      x -> raise "can't convert #{inspect x} to a positive integer"
    end
  end

  def parse!(input, _parsers, {:atom, []}) do
    case input do
      x when is_binary(x) -> String.to_atom(x)
      x when is_atom(x) -> x
      x -> raise "can't convert #{inspect x} to an atom"
    end
  end

  def parse!(input, _parsers, {:atom, val}) do
    val_string = Atom.to_string(val)

    case input do
      ^val -> val
      ^val_string -> val
      x -> raise "can't convert #{inspect x} into #{inspect val}"
    end
  end

  def parse!(input, _parsers, {:boolean, []}) do
    case input do
      x when is_boolean(x) -> x
      x -> raise "can't convert #{inspect x} to a boolean"
    end
  end

  def parse!(input, _parsers, {:float, []}) do
    case input do
      x when is_number(x) -> x
      x -> raise "can't convert #{inspect x} to a float"
    end
  end

  def parse!(input, parsers, {{module, type}, params}) do
    cond do
      f = Map.get(parsers, {module, type}) -> apply(f, [input | params])
      function_exported?(module, :__forma__, 2) -> apply(module, :__forma__, [type, input]  ++ params)
      true ->
        case Forma.type(module, type) do
          :opaque -> raise "{#{module}, #{type}} is opaque and no parser or parser behaviour is defined"
          typ -> parse!(input, parsers, typ)
        end
    end
  end

  def parse!(input, _parsers, {:any, []}), do: input
  def parse!(_input, _parsers, type) do
    raise "type #{inspect type} is not implemented yet"
  end

  defp map_assoc_fields!(input, parsers, acc, {key, value}) do
    Enum.reduce(input, acc, fn {k, v}, acc ->
      Map.put(acc, parse!(k, parsers, key), parse!(v, parsers, value))
    end)
  end

  defp map_exact_fields!(input, parsers, acc, fields) do
    Enum.reduce(input, acc, fn {key, value}, acc ->
      {field, type} = Map.get(fields, key)
      Map.put(acc, field, parse!(value, parsers, type))
    end)
  end
end
