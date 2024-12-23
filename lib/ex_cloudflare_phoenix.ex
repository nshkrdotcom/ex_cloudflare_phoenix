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





defmodule ExCloudflarePhoenix do
  @moduledoc """
   Provides UI components and behaviors for Cloudflare Calls
   and Durable Object integration within a phoenix application
  """
    alias ExCloudflarePhoenix.Behaviours
      alias ExCloudflarePhoenix.Components
      alias ExCloudflarePhoenix.Presence
        alias ExCloudflarePhoenix.Media
  @doc """
     Provides user friendly abstractions for building interactive apps.
   """
  defmodule Agent do
        @doc """
          An OpenAI Implemenation for agentic behaviours.
        """
    defmodule OpenAI do
      @spec new_agent(String.t(), String.t(), String.t(), keyword) ::
        {:ok, map()} | {:error, String.t()}
      def new_agent(app_id, app_token, open_ai_model_endpoint, opts \\ []) do
        ExCloudflareAgent.Implementations.OpenAIAgent.new_agent(app_id, app_token, open_ai_model_endpoint, opts)
      end

      @spec manage_tracks(String.t(), String.t(), String.t(), String.t(), keyword) ::
              {:ok, map()} | {:error, String.t()}
     def manage_tracks(session_id, app_id, track_id, mid, opts \\ []) do
          ExCloudflareAgent.Implementations.OpenAIAgent.manage_tracks(session_id, app_id, track_id, mid, opts)
       end
  end
    end

      @doc """
       Provides composable LiveView UI components
      """
  defmodule Components do
        use Phoenix.Component

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

    @doc """
    Defines the contract for a room behaviour. Use this to establish a common behaviour for any implementation of a room.
    """
  defmodule Behaviours.Room do
        @callback handle_join(room :: term(), user :: term()) :: {:ok, term()} | {:error, term()}
        @callback handle_leave(room :: term(), user :: term()) :: :ok | {:error, term()}
        @callback handle_message(room :: term(), from :: term(), message :: term()) :: :ok | {:error, term()}
        @callback broadcast_state(room :: term()) :: :ok | {:error, term()}

        defmacro __using__(_opts) do
          quote do
             use Phoenix.Channel

            import ExCloudflarePhoenix.Presence, only: [track_user: 3, untrack_user: 2, list: 1]

            def join("room:" <> room_id, _params, socket) do
                # Track user using the Presence module
              with {:ok, room} <- init(room_id) do
                {:ok, assign(socket, :room, room),
                push: %{event: "joined_room", payload:  %{id: room_id}}}
                 else
                   {:error, reason} ->
                    {:error, reason}
                    end
            end

            def handle_in("userUpdate", %{"user" => user}, socket) do
                 with {:ok, socket} <- update_presence(socket, user) do
                  {:noreply, socket}
                 else
                    {:error, reason} ->
                        Logger.error("Error updating presence: #{reason}")
                        {:noreply, socket}
                  end
            end

            def handle_in("message", %{"from" => from, "message" => message}, socket) do
                  case handle_message(socket.assigns.room, from, message) do
                    :ok ->
                        {:noreply, socket}
                    {:error, reason} ->
                        Logger.error("Error handling message: #{reason}")
                        {:noreply, socket}
                  end
            end

            def handle_in("heartbeat", _payload, socket) do
                send(self(), {:heartbeat, socket.assigns.room})
                {:noreply, socket}
            end

            def handle_in("enableAi", %{"instructions" => instructions, "voice" => voice}, socket) do
                #  TODO: implementation
                send(self(), {:enableAi, socket.assigns.room, instructions, voice})
                {:noreply, socket}
            end

            def handle_info(:broadcast_state, socket) do

               case broadcast_state(socket.assigns.room) do
                :ok ->
                  schedule_state_broadcast(socket)
                 {:error, reason} ->
                     Logger.error("Error broadcasting state: #{reason}")
                    schedule_state_broadcast(socket)
                end
              {:noreply, socket}
              end

            def handle_info({:heartbeat, room}, socket) do
                Logger.debug("received heartbeat: #{room.id}")
                  send_after(self(), :broadcast_state, 15_000)
                  {:noreply, socket}
              end

            def handle_info({:enableAi, room, instructions, voice}, socket) do
                   Logger.debug("received enableAi request: #{room.id} with instructions: #{instructions} and voice: #{voice}")
                #  TODO: implement
                {:noreply, socket}
              end

            def handle_leave(socket) do
                case untrack_user(socket, socket.assigns.user_id) do
                 :ok ->
                    {:noreply, socket}
                 {:error, reason} ->
                    Logger.error("Error handling user leave: #{reason}")
                    {:noreply, socket}
                 end

            end

        defp broadcast_room_state(socket) do
          presence_state = Presence.list(socket)
          users = format_users(presence_state)

          broadcast!(socket, "roomState", %{
              type: "roomState",
                state: %{
                    meetingId: socket.assigns.room.id,
                  users: users,
                  ai: %{enabled: false} # Match Orange's AI state structure
                }
          })
        end

        defp update_presence(socket, user) do
            Presence.update(socket, user.id, fn meta ->
              Map.merge(meta, user)
            end)

        end

            # Periodic state broadcast (replacing Orange's alarm system)
          def schedule_state_broadcast(socket) do
              Process.send_after(self(), :broadcast_state, 15_000)
          end

          def format_users(presence) do
            Enum.map(presence, fn {user_id, user_state} ->
                Map.get(user_state, :user, %{}) |> Map.put(:id, user_id)
            end)
          end
        end
    end

    @doc """
      Implements the presence API. This abstracts away the implementation of Phoenix Presence, but provides user tracking via the same protocol that was used in the reference application.
     """
  defmodule Presence do
    use Phoenix.Presence

    @doc """
        Tracks a user using a provided meta.
    """
    @spec track_user(Phoenix.Socket.t(), String.t(), map()) :: :ok | {:error, String.t()}
    def track_user(socket, user_id, meta) do
      try do
          track(socket, user_id, meta)
      catch
          _reason ->
           Logger.error("Error tracking presence of user with id: #{user_id}")
             {:error, "Error tracking presence of user"}
       end
   end

        @doc """
          Untracks a user in a presence context.
        """
        @spec untrack_user(Phoenix.Socket.t(), String.t()) :: :ok | {:error, String.t()}
        def untrack_user(socket, user_id) do
            try do
            untrack(socket, user_id)
             catch
                _reason ->
                    Logger.error("Error untracking presence of user with id: #{user_id}")
                 {:error, "Error untracking presence of user"}
            end
        end

         @doc """
          Lists all current presences
         """
          @spec list(Phoenix.Socket.t()) :: list(map())
        def list(socket) do
             list(socket.assigns.room_name)
        end
  end

    @doc """
    A generic integration module to manage user media and the corresponding calls api interactions.
    """
  defmodule Media do
    require Logger
        alias ExCloudflarePhoenix.Behaviours.Room

         @spec handle_tracks(Phoenix.Socket.t(), list(map())) ::
              :ok | {:error, String.t()}
        def handle_tracks(socket, tracks) do

          with {:ok, session} <- ExCloudflareCalls.Session.get_session(socket.assigns.room.calls_session.session_id),
               {:ok, _} <- ExCloudflareCalls.Session.new_tracks(session.session_id,  config(:app_id), tracks, app_token: config(:secret) )  do
                broadcast_track_update(socket, tracks)
            else
               {:error, reason} ->
                    Logger.error("Error adding new track: #{reason}")
                    {:error, "Failed to update track info"}
               end
        end

    defp broadcast_track_update(socket, tracks) do
      # TODO: add client update logic
    end
  end
end
