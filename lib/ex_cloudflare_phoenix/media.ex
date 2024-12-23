defmodule ExCloudflarePhoenix.Media do
  require Logger
  alias ExCloudflarePhoenix.Behaviours
  alias ExCloudflarePhoenix.Components
  alias ExCloudflarePhoenix.Presence
  alias ExCloudflarePhoenix.Media
  alias ExCloudflarePhoenix.Behaviours.Room
  alias ExCloudflareCalls
          @spec handle_tracks(Phoenix.Socket.t(), list(map())) ::
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
