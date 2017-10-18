defmodule Forma.Types do
  use GenServer

  def for(pid \\ __MODULE__, module, type) do
          GenServer.call(pid, {:type, module, type})
      end

  def start_link(args) do
    GenServer.start_link(__MODULE__, %{}, args)
  end

  def init(initial) do
    {:ok, initial}
  end

  def handle_call({:type, module, t}, _from, state) do
    case Map.get(state, module) do
      nil -> types = Forma.Typespecs.compile(module)
      {:reply, Map.get(types, {module, t}), Map.merge(state, types)}
      type -> {:reply, type, state}
    end
  end
end
