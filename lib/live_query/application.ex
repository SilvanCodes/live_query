defmodule LiveQuery.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: LiveQuery.PubSub}
      # Starts a worker by calling: LiveQuery.Worker.start_link(arg)
      # {LiveQuery.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveQuery.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
