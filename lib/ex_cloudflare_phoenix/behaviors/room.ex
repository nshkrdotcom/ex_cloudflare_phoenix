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
