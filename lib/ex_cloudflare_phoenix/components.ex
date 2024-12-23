defmodule ExCloudflarePhoenix.Application do
  use Application

  def start(_type, _args) do
    children = [
      # Presence supervisor
      ExCloudflarePhoenix.Presence
    ]

    opts = [strategy: :one_for_one, name: ExCloudflarePhoenix.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
