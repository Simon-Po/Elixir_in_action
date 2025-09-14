defmodule Todo.Application do
  use Application 
  def start(_start_type, _start_args) do
    Todo.System.start_link() 
  end
end
