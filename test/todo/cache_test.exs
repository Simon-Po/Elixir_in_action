defmodule Todo.CacheTest do
  use ExUnit.Case
  test "server_process" do                                       
    Todo.Cache.start()
    bob_pid = Todo.Cache.server_process("bob")
 
    assert bob_pid != Todo.Cache.server_process("alice")  
    assert bob_pid == Todo.Cache.server_process("bob")
    Todo.Cache.stop()
  end
  test "to-do operations" do
    Todo.Cache.start()
 
    alice = Todo.Cache.server_process("alice")
    Todo.Server.add_entry(alice, %{date: ~D[2023-12-19], title: "Dentist"})
 
    entries = Todo.Server.entry(alice, ~D[2023-12-19])
    assert [%{date: ~D[2023-12-19], title: "Dentist"}] = entries
    Todo.Cache.stop()
  end
end
