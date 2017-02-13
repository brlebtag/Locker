defmodule Locker do
  defstruct done: {:ok, nil},
    pid: nil
  
  @doc """
  create a locker to store key, value pairs
  """
  def create() do
    case Agent.start_link(fn -> %{} end) do
      {:ok, pid} -> %Locker{ pid: pid }
      {:_error, reason} -> %Locker{ done: {:_error, reason}}
    end
  end

  @doc """
  Store a value inside a key. Any error is ignored
  """
  def put(%{done: {:_error, _}} = state, _, _), do: state
  def put(state, key, value) do
    _update(state.pid, key, value)
    state
  rescue
    e -> _error(state, e)
  end

  @doc """
  Store a previously retrieved value inside the given key. Any error is ignored
  """
  def put(%{done: {:_error, _}} = state, _), do: state
  def put(state, key) do
    _update(state.pid, key, Kernel.elem(state.done, 1))
    state
  rescue
    e -> _error(state, e)
  end

  @doc """
  Retrieve a value and keep it in the state itself. Any error is ignored
  """
  def get(state, key, default \\ nil)
  def get(%{done: {:_error, _}} = state, _, _), do: state
  def get(state, key, default) do
    value = _get(state.pid, key, default)
    Map.put(state, :done, {:ok, value})
  rescue
    e -> _error(state, e)
  end

  @doc """
  Retrieve a value and return it. Any error is ignored
  """
  def get!(state, key, default \\ nil)
  def get!(%{done: {:_error, _}} = state, _, _), do: state
  def get!(state, key, default) do
    _get(state.pid, key, default)
  rescue
    e -> _error(state, e)
  end

  @doc """
  Convert the locker into a list and return it
  """
  def to_list!(%{done: {:_error, _}} = state), do: state
  def to_list!(state) do
    _to_list(state.pid)
  rescue
    e -> _error(state, e)
  end

  @doc """
  Return a list of all keys stored inside the locker
  """
  def keys!(%{done: {:_error, _}} = state), do: state
  def keys!(state) do
    _keys(state.pid)
  rescue
    e -> _error(state, e)
  end

  @doc """
  Return a list of values stores inside the locker
  """
  def values!(%{done: {:_error, _}} = state), do: state
  def values!(state) do
    _values(state.pid)
  rescue
    e -> _error(state, e)
  end

  @doc """
  Check if the given key exists inside the locker
  """
  def has_key?(%{done: {:_error, _}}, _), do: :ok
  def has_key?(state, key) do
    _has_key?(state.pid, key)
  rescue
    e -> _error(state, e)
  end

  @doc """
  Destroy the locker
  """
  def destroy(%{done: {:_error, _}}), do: :ok
  def destroy(state) do
    Agent.stop(state)
    :ok
  end

  #
  # Private Methods
  #

  defp _error(state, e) do
    Map.put(state, :done, {:_error, e})
  end

  def bucket(state) do
    Agent.get(state.pid, fn bucket -> bucket end)
  end

  defp _update(pid, key, value) do
    Agent.update(pid, fn bucket -> Map.put(bucket, key, value) end)
  end

  defp _get(pid, key, default) do
    Agent.get(pid, fn bucket -> Map.get(bucket, key, default) end)
  end

  defp _values(pid) do
    Agent.get(pid, fn bucket -> Map.values(bucket) end)
  end

  defp _keys(pid) do
    Agent.get(pid, fn bucket -> Map.keys(bucket) end)
  end

  defp _to_list(pid) do
    Agent.get(pid, fn bucket -> Map.to_list(bucket) end)
  end

  defp _delete(pid, key) do
    Agent.get_and_update(pid, &Map.pop(&1, key))
  end

  defp _clear(pid, key, value) do
    Agent.update(pid, fn bucket -> %{} end)
  end

  defp _has_key?(pid, key) do
    Agent.get(pid, fn bucket -> Map.has_key?(bucket, key) end)
  end
end
