@moduledoc """
  Provides UI components and behaviors for Cloudflare Calls
  and Durable Object integration within a phoenix application
  """
defmodule ExCloudflarePhoenix.Components do

  use Phoenix.Component

  alias ExCloudflarePhoenix.Behaviours
  alias ExCloudflarePhoenix.Components
  alias ExCloudflarePhoenix.Presence
  alias ExCloudflarePhoenix.Media
  alias CfCore.SDP
  alias CfCalls
  alias CfCore

  @doc """
    Provides a composable UI component for building a room layout.
    """
  def room(assigns) do
    ~H"""
    <div>
      <.media_grid users={@room.users} />
      <.controls room={@room} />
      <.chat messages={@room.messages} />
    </div>
    """
  end

  @doc """
    Provides a component for rendering a participant's media.
    """
  def media_grid(assigns) do
    ~H"""
    <div class="grid">
      <%= for user <- @users do %>
        <.media_tile user={user} />
      <% end %>
    </div>
    """
  end

end
