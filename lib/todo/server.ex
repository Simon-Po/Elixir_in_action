# lib/todo/server.ex
defmodule Todo.Server do
  use GenServer, restart: :temporary

  # ----- public API -----

  def start_link(name) do
    GenServer.start_link(__MODULE__, {name,[]}, name: via_tuple(name))
  end
 
  defp via_tuple(name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, name})
  end

  def add_entry(pid, entry),           do: GenServer.cast(pid, {:add_entry, entry})
  def update_entry(pid, id, fun),      do: GenServer.cast(pid, {:update_entry, id, fun})
  def delete_entry(pid, id),           do: GenServer.cast(pid, {:delete_entry, id})
  def entry(pid, date),                do: GenServer.call(pid, {:entries, date})
  def entries(pid),                    do: GenServer.call(pid, :entries)

  # name-registered API (if started with name: __MODULE__)
  def add_entry(entry),                do: GenServer.cast(__MODULE__, {:add_entry, entry})
  def update_entry(id, fun),           do: GenServer.cast(__MODULE__, {:update_entry, id, fun})
  def delete_entry(id),                do: GenServer.cast(__MODULE__, {:delete_entry, id})
  def entry(date),                     do: GenServer.call(__MODULE__, {:entries, date})
  def entries(),                       do: GenServer.call(__MODULE__, :entries)





  #  GenServer callbacks 

  @impl GenServer
  def init({name, initial_list}) do
    IO.puts "Starting Todo Server for #{name}"
    {:ok, {name, initial_list}, {:continue, :load_from_db}}
  end

  @impl true
  def handle_continue(:load_from_db, {name, _initial}) do
    todo_list = Todo.Database.get(name) || %Todo.List{}
    {:noreply, {name, todo_list}}
  end

  @impl GenServer
  def handle_cast({:add_entry, entry}, {name, list}) do
    new_list = Todo.List.add_entry(list, entry)
    Todo.Database.store(name, new_list)
    {:noreply, {name, new_list}}
  end

  def handle_cast({:update_entry, id, fun}, {name, list}) do
    new_list = Todo.List.update_entry(list, id, fun)
    Todo.Database.store(name, new_list)
    {:noreply, {name, new_list}}
  end

  def handle_cast({:delete_entry, id}, {name, list}) do
    new_list = Todo.List.delete_entry(list, id)
    Todo.Database.store(name, new_list)
    {:noreply, {name, new_list}}
  end

  @impl GenServer
  def handle_call({:entries, date}, _from, {name, list}) do
    {:reply, Todo.List.entries(list, date), {name, list}}
  end

  def handle_call(:entries, _from, {name, list}) do
    {:reply, Todo.List.entries(list), {name, list}}
  end
end
