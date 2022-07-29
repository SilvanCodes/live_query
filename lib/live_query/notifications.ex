defmodule LiveQuery.Notifications do
  @moduledoc """
  Notification mechanism for changes in PostgreSQL database tables.

  Notifications work via the
  """
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
    if Phoenix.LiveView.connected?(socket), do: receive_notifications_for(tables)
    {:cont, socket}
  end

  defp receive_notifications_for(tables) do
    for table <- tables do
      IO.puts("listening to #{table}")
      {:ok, _listen_ref} = Postgrex.Notifications.listen(LiveQuery.Notifications, table)
    end
  end
end
