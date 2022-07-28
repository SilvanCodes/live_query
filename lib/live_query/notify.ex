defmodule LiveQuery.Notify do
  defmacro __using__(opts) do
    tables =
      case opts[:tables] do
        tables when is_list(tables) ->
          tables

        other ->
          raise ArgumentError,
                ":tables expects a list of table names of the from [\"my_table\", \"my_other_table\"]" <>
                  "got: #{inspect(other)}"
      end

    quote bind_quoted: [tables: tables] do
      Module.register_attribute(__MODULE__, :live_query_notifications_for, persist: true)
      Module.put_attribute(__MODULE__, :live_query_notifications_for, tables)

      on_mount({LiveQuery.Notify, tables})
    end
  end

  def on_mount(tables, _params, _session, socket) when is_list(tables) do
    on_changes(tables)
    {:cont, socket}
  end

  defp on_changes(tables) do
    for table <- tables do
      IO.puts("subscribing to #{table}")
      Phoenix.PubSub.subscribe(LiveQuery.PubSub, table)
    end
  end
end
