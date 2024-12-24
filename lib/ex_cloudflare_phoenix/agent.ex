
@doc """
    Provides user friendly abstractions for building interactive apps.
  """
defmodule Agent do
  alias ExCloudflarePhoenix.Behaviours
  alias ExCloudflarePhoenix.Components
  alias ExCloudflarePhoenix.Presence
  alias ExCloudflarePhoenix.Media

  @doc """
    An OpenAI Implementation for agentic behaviours.
  """
  defmodule OpenAI do
    @spec new_agent(String.t(), String.t(), String.t(), keyword) ::
      {:ok, map()} | {:error, String.t()}
    def new_agent(app_id, app_token, open_ai_model_endpoint, opts \\ []) do
      with  {:ok, session} <- CfCalls.Session.new_session(app_id, app_token, thirdparty: true, opts),
        {:ok, offer} <- CfCalls.Session.new_tracks(session.session_id, app_id,
        [%{
          location: "local",
          trackName: "ai-generated-voice",
          bidirectionalMediaStream: true,
          kind: "audio"
          ## TODO: move any URLs to cloudflare into the base lib:
        }], app_token: app_token , base_url: Keyword.get(opts, :base_url, "https://rtc.live.cloudflare.com")),
        {:ok, openai_answer} <- ExCloudflareCore.API.request(:post,  open_ai_model_endpoint,
          [{'Authorization', "Bearer #{Keyword.fetch!(opts, :open_ai_token)}"}, {'Content-Type', 'application/sdp'}]
            ,  offer.sessionDescription.sdp),
        {:ok, openai_sdp} <- case String.starts_with?(openai_answer.body, "v=") do
          true -> {:ok, SDP.generate_sdp(openai_answer.body)}
          _ -> {:error, "Invalid response from Open AI"}
      end,
      {:ok, _renegotiated} <- CfCalls.Session.renegotiate(session.session_id, app_id,  openai_sdp, "answer", app_token: app_token, base_url: Keyword.get(opts, :base_url, "https://rtc.live.cloudflare.com")) do
        {:ok, %{session_id: session.session_id, audio_track:  List.first(offer.tracks).trackName }}
      else
        {:error, reason} ->
        {:error, "Failed to create new OpenAI agent: #{reason}"}
      end
    end

    @spec manage_tracks(String.t(), String.t(), String.t(), String.t(), keyword) ::
      {:ok, map()} | {:error, String.t()}
    def manage_tracks(session_id, app_id, track_id, mid, opts \\ []) do
      CfCalls.Session.new_tracks(session_id, app_id,
        [tracks: [%{
          location: "remote",
          sessionId: session_id,
          trackName: track_id,
          mid: mid
        }]], opts
      )
    end
  end
end
