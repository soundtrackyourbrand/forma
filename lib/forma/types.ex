defmodule Forma.Types do
  use GenServer

  def for(module, type) do
    case get({module, type}) do
      nil -> GenServer.call(__MODULE__, {:compile, {module, type}})
      spec -> spec
    end
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, :start, args)
  end

  def init(:start) do
    name = :ets.new(__MODULE__, [:set, :protected, :named_table])
    {:ok, name}
  end

  def handle_call({:compile, {_module, _t} = k}, _from, name) do
    spec = case get(k) do
      nil ->
        spec = compile(k)
        true = :ets.insert(name, {k, spec})
        spec
      spec -> spec
    end
    {:reply, spec, name}
  end

  defp compile({module, type}) do
    types = Forma.Typespecs.compile(module)
    Map.get(types, {module, type})
  end

  defp get({module, type}) do
    case :ets.lookup(__MODULE__, {module, type}) do
      [] -> nil
      [{{_, _}, spec} | _] -> spec
    end
  end
end
