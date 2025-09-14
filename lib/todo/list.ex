defmodule Todo.List do
  @moduledoc false

  defstruct next_id: 1, entries: %{}

  @type entry ::
          %{
            required(:date) => Date.t(),
            required(:title) => String.t(),
            optional(:id) => pos_integer()
          }

  @type t :: %__MODULE__{
          next_id: pos_integer(),
          entries: %{optional(pos_integer()) => entry()}
        }

  @spec new([entry()]) :: t()
  def new(entries \\ []) do
    for entry <- entries, into: %Todo.List{}, do: entry
  end

def add_entry(%Todo.List{entries: entries, next_id: id} = todo_list, entry) do
    entry = Map.put(entry, :id, id)

    %Todo.List{
      todo_list
      | entries: Map.put(entries, id, entry),
        next_id: id + 1
    }
  end

  @spec entries(t(), Date.t()) :: [entry()]
  def entries(todo_list, date) do
    todo_list.entries
    |> Map.values()
    |> Enum.filter(fn entry -> entry.date == date end)
  end

  def entries(todo_list) do
    todo_list.entries
    |> Map.values()
  end

  @spec update_entry(t(), pos_integer(), (entry() -> entry())) :: t()
  def update_entry(todo_list, entry_id, updater_fun) do
    case Map.fetch(todo_list.entries, entry_id) do
      :error ->
        todo_list

      {:ok, old_entry} ->
        new_entry = updater_fun.(old_entry)
        new_entries = Map.put(todo_list.entries, new_entry.id, new_entry)
        %Todo.List{todo_list | entries: new_entries}
    end
  end

  @spec delete_entry(t(), pos_integer()) :: t()
  def delete_entry(todo_list, entry_id) do
    new_entries = Map.delete(todo_list.entries, entry_id)
    %Todo.List{todo_list | entries: new_entries}
  end
end

defmodule Todo.List.CsvImporter do
  @moduledoc false

  @spec import!(Path.t()) :: Todo.List.t()
  def import!(path) do
    File.stream!(path)
    |> Stream.map(&String.trim/1)
    |> Stream.map(&parse_line!/1)
    |> Todo.List.new()
  end

  @spec import_list!(Path.t()) :: list()
  def import_list!(path) do
    File.stream!(path)
    |> Stream.map(&String.trim/1)
    |> Enum.map(&parse_line!/1)
  end

  @spec parse_line!(String.t()) :: %{date: Date.t(), title: String.t()}
  defp parse_line!(line) do
    case String.split(line, ",", parts: 2) do
      [date_str, title] ->
        case Date.from_iso8601(date_str) do
          {:ok, date} -> %{date: date, title: title}
          {:error, _} -> raise ArgumentError, "invalid ISO8601 date: #{inspect(date_str)}"
        end

      other ->
        raise ArgumentError, "invalid CSV line (expected \"YYYY-MM-DD,Title\"): #{inspect(other)}"
    end
  end

  # defp parse_line(line) do
  #   case String.split(line, ",", parts: 2) do
  #     [date_str, title] ->
  #       case Date.from_iso8601(date_str) do
  #         {:ok, date} -> {:ok, %{date: date, title: title}}
  #         {:error, reason} -> {:error, reason}
  #       end
  #
  #     _ ->
  #       {:error, :invalid_line}
  #   end
  # end
end

defimpl Collectable, for: Todo.List do
  def into(original) do
    {original, &into_callback/2}
  end

  defp into_callback(todo_list, {:cont, entry}) do
    Todo.List.add_entry(todo_list, entry)
  end

  defp into_callback(todo_list, :done), do: todo_list
  defp into_callback(_todo_list, :halt), do: :ok
end
