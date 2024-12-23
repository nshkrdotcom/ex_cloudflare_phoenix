
@doc """
  Implements the presence API. This abstracts away the implementation of Phoenix Presence, but provides user tracking via the same protocol that was used in the reference application.
  """
  defmodule ExCloudflarePhoenix.Presence do
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
