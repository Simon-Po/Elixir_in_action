defmodule Todo.Metrics do
  use Task
  
  def start_link(_arg), do: Task.start_link(&loop/0)

    defp loop() do
    Process.sleep(:timer.seconds(10))
    IO.inspect(collect_metrics())
    loop()
  end
 
  defp collect_metrics() do
    [
      memory_usage: inspect(Float.round(:erlang.memory(:total) / (1024 * 1024 * 1024),3)) <> "GB",
      process_count: :erlang.system_info(:process_count)
    ]
  end 
end
