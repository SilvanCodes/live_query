defmodule LiveQuery.NotificationsTest do
  use ExUnit.Case, async: true

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @endpoint LiveQuery.TestEndpoint

  defmodule TestLive do
    use Phoenix.LiveView

    use LiveQuery.Notifications, for: ["test_table"]

    def render(assigns) do
      ~H"""
      <h1>TestLive: <%= @status %></h1>
      """
    end

    def mount(_params, _conn, socket) do
      socket = assign(socket, status: :fresh)
      {:ok, socket}
    end

    def handle_info({:live_query_notification, %{table: "test_table"}}, socket) do
      socket = assign(socket, status: :notified)
      {:noreply, socket}
    end
  end

  test "LiveView mounts" do
    {:ok, view, html} = live_isolated(build_conn(), TestLive)

    assert html =~ "TestLive: fresh"

    broadcast_live_query_message("test_table")

    assert render(view) =~ "TestLive: notified"
  end

  defp broadcast_live_query_message(channel) do
    Phoenix.PubSub.broadcast(
      LiveQuery.PubSub,
      "live_query:#{channel}",
      {:live_query_notification, %{table: channel}}
    )
  end
end
