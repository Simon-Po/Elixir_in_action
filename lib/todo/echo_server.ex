defmodule EchoServer do
  use GenServer

  
  def start(id) do
    GenServer.start_link(__MODULE__,nil,name: via_tuple(id)) 
  end
  def init(_) do
    {:ok,nil}
  end

  def echo(id,value) do
    GenServer.call(via_tuple(id),{:echo,value})
  end

  defp via_tuple(id) do
    {:via, Registry, {:my_registry, {__MODULE__, id}}}          
  end
  
  def handle_call({:echo,val}, _, state) do
   {:reply,val,state} 
  end

end
