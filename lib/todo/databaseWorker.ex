defmodule Todo.DatabaseWorker do
  use GenServer

  def start_link({db_folder, worker_id}) do
    GenServer.start_link(__MODULE__, db_folder, name: via_tuple(worker_id))
  end

  @impl true
  def init(db_folder) do
    IO.puts("Starting database worker")
    {:ok, db_folder}
  end

  def store(worker_id, key, data) do
    GenServer.cast(via_tuple(worker_id), {:store, key, data})
  end

  def get(worker_id, key) do
    GenServer.call(via_tuple(worker_id), {:get, key})
  end

  defp via_tuple(worker_id) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, worker_id})
  end

  @impl true
  def handle_cast({:store, key, data}, db_folder) do
    db_folder
    |> file_name(key)
    |> File.write!(:erlang.term_to_binary(data))

    # Optional: debug to see serialization per worker/key
    IO.inspect("#{inspect(self())}: stored #{inspect(key)}")

    {:noreply, db_folder}
  end

  @impl true
  def handle_call({:get, key}, _from, db_folder) do
    result =
      case File.read(file_name(db_folder, key)) do
        {:ok, contents} -> :erlang.binary_to_term(contents)
        _ -> nil
      end

    # Optional: debug
    # IO.inspect("#{inspect(self())}: read #{inspect(key)} -> #{inspect(result)}")

    {:reply, result, db_folder}
  end

  @impl true
  def handle_info(msg, state) do
    case msg do
      :ping -> IO.puts(:pong)
      _ -> IO.puts("I Dont know " <> inspect(msg))
    end

    {:noreply, state}
  end

  defp file_name(db_folder, key), do: Path.join(db_folder, to_string(key))
end
