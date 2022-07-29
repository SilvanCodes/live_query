defmodule LiveQuery.Listener do
  use GenServer

  defstruct [:listen_ref, :notifyee_refs]

  ## CLIENT ##

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @spec listen_for(list(binary()), pid()) :: :ok
  def listen_for(tables, notifyee \\ self()) when is_list(tables) do
    GenServer.cast(__MODULE__, {:listen_for, tables: tables, notifyee: notifyee})
  end

  ## CALLBACKS ##

  def init(_state) do
    {:ok, %{}}
  end

  def handle_cast({:listen_for, tables: tables, notifyee: notifyee}, state) do
    notifyee_ref = Process.monitor(notifyee)

    state =
      for table <- tables do
        table_atom = table |> String.to_atom()

        listener =
          case state[table_atom] do
            listener = %__MODULE__{notifyee_refs: notifyee_refs} ->
              %__MODULE__{listener | notifyee_refs: [notifyee_ref | notifyee_refs]}

            nil ->
              ensure_table_trigger_exists(table)
              {:ok, listen_ref} = Postgrex.Notifications.listen(LiveQuery.Notifications, table)
              %__MODULE__{listen_ref: listen_ref, notifyee_refs: [notifyee_ref]}
          end

        {table_atom, listener}
      end
      |> Map.new()

    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, _object, _reason}, state) do
    state =
      state
      |> Map.to_list()
      |> Enum.map(fn {table, listener} ->
        case listener do
          %__MODULE__{listen_ref: listen_ref, notifyee_refs: [^ref]} ->
            :ok = Postgrex.Notifications.unlisten(LiveQuery.Notifications, listen_ref)

            {table, nil}

          listener = %__MODULE__{notifyee_refs: notifyee_refs} ->
            %__MODULE__{listener | notifyee_refs: notifyee_refs |> Enum.filter(&(&1 != ref))}
        end
      end)
      |> Map.new()

    {:noreply, state}
  end

  defp ensure_table_trigger_exists(_table) do
    # warn or error when does not exist
    true
  end
end
