defmodule LiveQuery.Listener do
  use GenServer

  defstruct [:listen_ref, :notifyee_refs]

  ## CLIENT ##

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @spec listen_for(list(binary()), pid()) :: :ok
  def listen_for(tables, notifyee \\ self()) when is_list(tables) do
    GenServer.cast(__MODULE__, {:listen_for, tables: tables, notifyee: notifyee})
  end

  ## CALLBACKS ##

  def init(_opts) do
    {:ok, %{}}
  end

  @doc """
  Called when a LiveView with `use LiveQuery.Notifications``mounts.any()

  Adds that LiveView process to the list of notifyees and starts listening for any table that LiveView is the first on to be notified about.
  """
  def handle_cast({:listen_for, tables: tables, notifyee: notifyee}, state) do
    notifyee_ref = Process.monitor(notifyee)

    state =
      for table <- tables do
        table_atom = table |> String.to_atom()

        listener =
          case state[table_atom] do
            %__MODULE__{notifyee_refs: notifyee_refs} ->
              %__MODULE__{state[table_atom] | notifyee_refs: [notifyee_ref | notifyee_refs]}

            nil ->
              {:ok, listen_ref} = start_listen_for_table(table)
              %__MODULE__{listen_ref: listen_ref, notifyee_refs: [notifyee_ref]}
          end

        {table_atom, listener}
      end
      |> Enum.into(state)

    {:noreply, state}
  end

  @doc """
  Called when a LiveView process ends.

  Unlistens from any tables when that LiveView was the last process interested in notifications about those tables.
  """
  def handle_info({:DOWN, ref, :process, _object, _reason}, state) do
    state =
      state
      |> Enum.map(fn {table, listener} ->
        case listener do
          %__MODULE__{listen_ref: listen_ref, notifyee_refs: [^ref]} ->
            stop_listen_for_table(listen_ref)
            {table, nil}

          %__MODULE__{notifyee_refs: notifyee_refs} ->
            %__MODULE__{listener | notifyee_refs: notifyee_refs |> Enum.filter(&(&1 != ref))}
        end
      end)
      |> Enum.into(state)

    {:noreply, state}
  end

  @doc """
  Called when any listened channel receives a notification.

  Send from Postgrex.Notifications.
  """
  def handle_info({:notification, _connection_pid, _listen_ref, channel, _payload}) do
    Phoenix.PubSub.broadcast(
      LiveQuery.PubSub,
      "live_query:#{channel}",
      {:live_query_notification, %{table: channel}}
    )
  end

  defp start_listen_for_table(table) do
    ensure_table_trigger_exists(table)
    Postgrex.Notifications.listen(LiveQuery.Notifications, table)
  end

  defp stop_listen_for_table(listen_ref) do
    :ok = Postgrex.Notifications.unlisten(LiveQuery.Notifications, listen_ref)
  end

  defp ensure_table_trigger_exists(_table) do
    # warn or error when does not exist
  end
end
