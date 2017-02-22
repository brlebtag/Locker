defmodule LockerTest do
  use ExUnit.Case
  doctest Locker

  test "create locker" do
    assert is_pid(Locker.create())
  end
end
