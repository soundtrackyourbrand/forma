defmodule Forma.Types do
  use GenServer

  def for(module, type) do
    case :ets.lookup(__MODULE__, {module, type}) do
      [] -> GenServer.call(__MODULE__, {:type, module, type})
      [{{_, _}, spec} | _] -> spec
    end
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, :start, args)
  end

  def init(:start) do
    name = :ets.new(__MODULE__, [:set, :protected, :named_table])
    {:ok, name}
  end

  def handle_call({:type, module, t}, _from, name) do
    types = Forma.Typespecs.compile(module)
    spec = Map.get(types, {module, t})
    true = :ets.insert(name, {{module, t}, spec})
    {:reply, spec, name}
  end
end
