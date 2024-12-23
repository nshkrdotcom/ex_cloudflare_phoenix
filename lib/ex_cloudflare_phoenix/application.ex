defmodule ExCloudflarePhoenix.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Presence supervisor
      ExCloudflarePhoenix.Presence
    ]

    opts = [strategy: :one_for_one, name: ExCloudflarePhoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
