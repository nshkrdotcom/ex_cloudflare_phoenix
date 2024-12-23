defmodule ExCloudflarePhoenix do
  # Reusable LiveView Components
  defmodule Components do
    use Phoenix.Component

    def room(assigns) do
      ~H"""
      <div>
        <.media_grid users={@room.users} />
        <.controls room={@room} />
        <.chat messages={@room.messages} />
      </div>
      """
    end

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

  # Reusable Room Behavior
  defmodule RoomBehavior do
    @callback handle_join(room :: term(), user :: term()) :: {:ok, term()} | {:error, term()}
    @callback handle_leave(room :: term(), user :: term()) :: :ok | {:error, term()}
    @callback handle_message(room :: term(), from :: term(), message :: term()) :: :ok | {:error, term()}

    defmacro __using__(_opts) do
      quote do
        @behaviour ExCloudflarePhoenix.RoomBehavior
        use Phoenix.Channel

        def join("room:" <> room_id, _params, socket) do
          # Common room join logic
        end

        def handle_in("message", payload, socket) do
          # Common message handling
        end
      end
    end
  end

  # Presence Integration
  defmodule Presence do
    use Phoenix.Presence

    def track_user(room_id, user_id, meta) do
      # Track in both Phoenix and Durable Objects
      with :ok <- Phoenix.Presence.track(self(), "room:#{room_id}", user_id, meta),
           :ok <- ExCloudflareDurable.Room.put_presence(room_id, user_id, meta) do
        :ok
      end
    end
  end

  # Media Management
  defmodule Media do
    def handle_tracks(socket, tracks) do
      # Common media handling patterns
      with {:ok, session} <- ExCloudflareCalls.Session.get_session(socket.assigns.session_id),
           {:ok, _} <- ExCloudflareCalls.Session.new_tracks(session, tracks) do
        broadcast_track_update(socket, tracks)
      end
    end
  end
end
