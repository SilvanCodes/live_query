defmodule LiveQuery.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = children(Mix.env())

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveQuery.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp children(:test),
    do: [
      LiveQuery.TestEndpoint,
      {Phoenix.PubSub, name: LiveQuery.PubSub}
    ]

  defp children(:prod),
    do: [
      {Postgrex.Notifications, name: LiveQuery.Notifications},
      {Phoenix.PubSub, name: LiveQuery.PubSub}
    ]
end
