defmodule LiveQuery.Notifications do
  @moduledoc """
  Notification mechanism for changes in PostgreSQL database tables.

  Notifications work via the
  """

  require Logger

  defmacro __using__(opts) do
    tables =
      case opts[:for] do
        tables when is_list(tables) ->
          tables

        other ->
          raise ArgumentError,
                ":for expects a list of table names of the from [\"my_table\", \"my_other_table\"]" <>
                  "got: #{inspect(other)}"
      end

    quote bind_quoted: [tables: tables] do
      Module.register_attribute(__MODULE__, :live_query_notifications_for, persist: true)
      Module.put_attribute(__MODULE__, :live_query_notifications_for, tables)

      on_mount({LiveQuery.Notifications, tables})
    end
  end

  def on_mount(tables, _params, _session, socket) when is_list(tables) do
    if Phoenix.LiveView.connected?(socket) do
      Logger.info("LiveQuery: LiveView #{inspect(self())} is subscribing to #{inspect(tables)}")
      receive_notifications_for(tables)
    end

    {:cont, socket}
  end

  defp receive_notifications_for(tables) do
    tables
    |> Enum.map(fn table ->
      {table, Phoenix.PubSub.subscribe(LiveQuery.PubSub, "live_query:#{table}")}
    end)
    |> Enum.each(fn result ->
      case result do
        {table, :ok} ->
          {:ok, table}

        {table, {:error, error}} ->
          Logger.warn(
            "LiveQuery: LiveView #{inspect(self())} failed to subscribe to #{table} with #{inspect(error)}"
          )
      end
    end)
  end
end
