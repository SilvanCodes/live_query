defmodule Mix.Tasks.LiveQuery.Gen.Migration do
  @moduledoc """
  Generates a migration that creates all PostgreSQL triggers and trigger functions for all tables that occur in any `use LiveQuery.Notifications, for: [...]` list.
  """
  use Mix.Task

  @shortdoc "Generate migration to create PostgreSQL triggers and trigger functions for LiveQuery."
  def run(_) do
    Mix.Task.run("ecto.gen.migration", ["--change", postgresql_trigger_function()])

    modules_with_live_query =
      modules_with_persistent_module_attribute(:live_query_notifications_for)

    tables_in_live_queries =
      modules_with_live_query
      |> IO.inspect()
      |> Enum.flat_map(fn {_, attribute_values} -> attribute_values end)
      |> Enum.uniq()
      |> IO.inspect()
  end

  defp modules_with_persistent_module_attribute(attribute) when is_atom(attribute) do
    # Ensure the current projects code path is loaded
    Mix.Task.run("loadpaths", [])
    # Fetch all .beam files
    Path.wildcard(Path.join([Mix.Project.build_path(), "**/ebin/**/*.beam"]))
    # Parse the BEAM for behaviour implementations
    |> Stream.map(fn path ->
      {:ok, {mod, chunks}} = :beam_lib.chunks('#{path}', [:attributes])
      {mod, get_in(chunks, [:attributes, attribute])}
    end)
    # Filter modules with given attribute
    |> Stream.filter(fn {_mod, attribute_values} -> is_list(attribute_values) end)
    |> Enum.into([])
  end

  defp postgresql_trigger_function() do
    """
    CREATE OR REPLACE FUNCTION live_query.notify_about_changes_in_table() RETURNS trigger AS $live_query.notify_about_changes_in_table$
      BEGIN
        SELECT pg_notify(TG_TABLE_NAME, NULL);

        RETURN NULL;
      END;
    $live_query.notify_about_changes_in_table$ LANGUAGE plpgsql;
    """
  end

  defp postgres_trigger_for_table(table) do
    """
    CREATE OR REPLACE TRIGGER live_query__#{table}_changed
    AFTER INSERT OR UPDATE OR DELETE ON #{table}
      FOR EACH STATEMENT EXECUTE FUNCTION live_query.notify_about_changes_in_table();
    """
  end
end
