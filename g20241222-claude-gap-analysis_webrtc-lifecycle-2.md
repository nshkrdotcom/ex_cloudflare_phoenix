Now I can see both mapping files! Looking at them, I notice that my previous gap analysis was missing some key points from the Orange server mapping. Let me revise my WebRTC lifecycle management plan to better align with the Orange server's implementation:

Session Management with Cloudflare Calls
Code
CopyInsert

```python
defmodule ExCloudflarePhoenix.WebRTC.Session do
  @moduledoc """
  Manages WebRTC sessions through Cloudflare Calls API, aligning with Orange's implementation
  """
  
  alias ExCloudflareCalls.Session
  alias ExCloudflareCalls.TURN
  
  def create_session(config) do
    with {:ok, session} <- Session.new_session(config.app_id, config.app_token),
         {:ok, turn_key} <- TURN.create_turn_key(config.app_id, config.app_token) do
      {:ok, %{
        session_id: session.session_id,
        turn_credentials: turn_key
      }}
    end
  end
  
  def create_third_party_session(config) do
    # Special handling for AI integration, similar to Orange's implementation
    Session.new_session(config.app_id, config.app_token, thirdparty: true)
  end
end
```


Track Management (Matching Orange's Implementation)
Code
CopyInsert

```python
defmodule ExCloudflarePhoenix.WebRTC.Tracks do
  @moduledoc """
  Handles track management in alignment with Orange's implementation
  """
  
  def add_local_track(session, track_config) do
    ExCloudflareCalls.Session.new_tracks(
      session.session_id,
      session.app_id,
      [%{
        location: "local",
        trackName: track_config.name,
        kind: track_config.kind,
        bidirectionalMediaStream: track_config.bidirectional
      }],
      app_token: session.app_token
    )
  end
  
  def add_remote_track(session, remote_track) do
    ExCloudflareCalls.Session.new_tracks(
      session.session_id,
      session.app_id,
      [%{
        location: "remote",
        sessionId: remote_track.session_id,
        trackName: remote_track.track_name,
        mid: remote_track.mid
      }],
      app_token: session.app_token
    )
  end
end
```
Room State Management (Phoenix Channel Integration)
Code
CopyInsert
```python
defmodule ExCloudflarePhoenix.WebRTC.Room do
  @moduledoc """
  Manages room state and WebRTC connections, following Orange's ChatRoom.server.ts pattern
  """
  
  use Phoenix.Channel
  alias ExCloudflarePhoenix.Presence
  
  def join("room:" <> room_id, _params, socket) do
    with {:ok, room} <- init_room(room_id),
         :ok <- track_user(socket) do
      schedule_state_broadcast()
      {:ok, assign(socket, :room, room)}
    end
  end
  
  def handle_in("userUpdate", %{"tracks" => tracks}, socket) do
    # Handle track updates similar to Orange's implementation
    with {:ok, _} <- update_tracks(socket, tracks) do
      broadcast_room_state(socket)
      {:noreply, socket}
    end
  end
  
  defp schedule_state_broadcast do
    # Match Orange's periodic state broadcast
    Process.send_after(self(), :broadcast_state, 15_000)
  end
end
```
AI Integration (Matching Orange's OpenAI Integration)
Code
CopyInsert
```python
defmodule ExCloudflarePhoenix.WebRTC.AI do
  @moduledoc """
  Handles AI integration similar to Orange's openai.server.ts
  """
  
  def enable_ai(room, instructions, voice) do
    with {:ok, session} <- create_third_party_session(room.config),
         {:ok, offer} <- create_ai_offer(session),
         {:ok, ai_answer} <- request_openai_service(offer, instructions, voice),
         {:ok, _} <- handle_ai_answer(session, ai_answer) do
      {:ok, session}
    end
  end
  
  defp create_ai_offer(session) do
    ExCloudflareCalls.Session.new_tracks(
      session.session_id,
      session.app_id,
      [%{
        location: "local",
        trackName: "ai-generated-voice",
        bidirectionalMediaStream: true,
        kind: "audio"
      }]
    )
  end
end
```
Quality Monitoring (New Addition to Orange's Implementation)
Code
CopyInsert
```python
defmodule ExCloudflarePhoenix.WebRTC.Quality do
  @moduledoc """
  Enhances Orange's implementation with quality monitoring
  """
  
  def start_monitoring(connection) do
    # Initialize metrics collection
    schedule_stats_collection()
  end
  
  def handle_info(:collect_stats, state) do
    # Collect and store WebRTC stats
    schedule_stats_collection()
    {:noreply, state}
  end
end
```
Key Differences from Previous Plan:

More closely aligned with Orange's session management
Direct mapping to Cloudflare Calls API structure
Integration with Phoenix Channels for state management
Support for third-party sessions (AI integration)
Periodic state broadcasting matching Orange's implementation

