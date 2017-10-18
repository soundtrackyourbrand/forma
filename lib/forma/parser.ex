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
    ret = Enum.reduce_while(possible, :not_found, fn (candidate, _) ->
      try do
        {:halt, {:ok, parse!(input, parsers, candidate)}}
      rescue
        _ -> {:cont, {:error, :no_value}}
      end
    end)

    case ret do
      {:ok, v} -> v
      {:error, :no_value} -> raise "#{inspect input} doesn't match any of: #{inspect possible}"
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

  def parse!(input, _parsers, {:atom, nil}) do
    case input do
      nil -> nil
      "" -> nil
      x -> raise "can't convert #{inspect x} to nil"
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
        case Forma.Types.for(module, type) do
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
      case Map.get(fields, key) do
        {field, type} -> Map.put(acc, field, parse!(value, parsers, type))
        nil -> acc
      end
    end)
  end
end
