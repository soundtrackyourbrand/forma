defmodule Forma.Types do
  use GenServer

  def for(module, type) do
    case :ets.lookup(__MODULE__, {module, type}) do
      [] ->
        spec = compile(module, type)
        :ok = GenServer.call(__MODULE__, {:store, {module, type}, spec})
        spec
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

  def compile(module, type) do
    types = Forma.Typespecs.compile(module)
    Map.get(types, {module, type})
  end

  def handle_call({:store, {module, t}, spec}, _from, name) do
    true = :ets.insert(name, {{module, t}, spec})
    {:reply, :ok, name}
  end
end
