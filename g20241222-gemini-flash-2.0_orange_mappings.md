**Mapping from Orange (TypeScript) to Our Elixir Packages**

Here's a comprehensive breakdown, outlining how each component from the "orange" server finds its place in our Elixir architecture:

**1. Orange's `server.ts` (Main Worker Entry Point) Mapped Across Modules**

*   **Purpose:** This file acts as the main entry point for the Cloudflare Worker, handling incoming requests, routing them to either static asset handling or the core Remix application logic. It also defines `createKvAssetHandler` and has the durable object definitions.
*   **Mapping:**
    *   **Request Routing & Response:** The request handling logic (determining whether to serve assets, or pass the request to remix)  will be part of the Phoenix app entrypoint, and not in our packages.

    *   **`createKvAssetHandler`:** The asset handling logic (serving static files from KV) is also handled by the phoenix application. This won't live within our framework.

     * **Durable Object Definitions**: The Durable Object definitions (`ChatRoom`, are now in the `ex_cloudflare_durable` module.

    *  **`queue`:** Our `ex_cloudflare_service` will handle queue related activities, so the queue logic now lives in the service module.

*   **Code:**

    *   Most of the routing is within the phoenix application.

        *   This is a design choice to ensure that routing and the overall application structure remain composable.

    *   Durable Object code is within the `ex_cloudflare_durable` package

    *  Feedback queue is handled within `ex_cloudflare_service`.

**2. Orange's `app/durableObjects/ChatRoom.server.ts` (Durable Object Logic):**

*   **Purpose:** This file contains the core logic for the `ChatRoom` Durable Object, handling WebSocket connections, message broadcasting, presence tracking, and AI integration.
*  **Mapping:**
    *  **Core Durable Logic** The GenServer implementation in `ex_cloudflare_phoenix.Behaviours.Room` is designed to represent a single `ChatRoom` instance and implements logic for incoming messages, and periodic broadcast logic by leveraging `ex_cloudflare_durable.Object` to interact with durable objects, and `ex_cloudflare_calls` for media management (more details below).
    *  **User Session Tracking:** User Session data is maintained via Phoenix presence in the `ex_cloudflare_phoenix` package, though it also uses `ex_cloudflare_durable` for storage of the user data. The `ex_cloudflare_durable.Storage` module implements the DO storage primitives.
    *   **Connection Management:** The handling of WebSocket connections, message parsing, and broadcasting is abstracted through the Phoenix Channels with the `RoomBehaviour`.
        *  the message protocol is kept consistent with Orange to enable seamless transition.
         * `ex_cloudflare_phoenix.presence` implements the function calls related to presence.
    *   **AI Integration:**  The logic for interacting with OpenAI, handling AI voices, and track exchanges are performed by the `ex_cloudflare_service.OpenAI` module.
    *  **Peak User Count Tracking**  The logic for storing the peak user count is implemented using `ex_cloudflare_durable.Storage`.
*   **Code:**
    *   The Phoenix Channel implementation `ExCloudflarePhoenix.Behaviours.Room` maps almost directly to the structure provided by the reference Orange application (see section on Phoenix implementation for more details).
    * `ex_cloudflare_durable` implements a storage abstraction, and the `ex_cloudflare_service.OpenAI` handles all calls related to external AI services.
    *  `ex_cloudflare_phoenix.Media` helps manage the tracks.

**3. Orange's `app/queue.ts` (Queue Processing):**

*   **Purpose:** This file defines the logic for processing messages sent to the Cloudflare Queue (used primarily for feedback).
*   **Mapping:**
    *  `ex_cloudflare_service.Queue` (not fully implemented in the base setup yet) will serve as the abstraction for queue handling. For this initial proposal I am thinking a direct call to the url endpoint is good enough for most of the use cases, while a more robust implementation could exist at this level, such as sending batched messages.
 *  **Code**:
        * The `FEEDBACK_URL` handling will live inside `ex_cloudflare_service.Queue`, where an external fetch operation will occur against that url using httpoison.

**4. Orange's `app/utils/openai.server.ts` (OpenAI Integration):**

*   **Purpose:** This utility file contains logic for sending SDP offers to OpenAI and handling the response.
*   **Mapping:**
    *   The core logic for sending SDPs to OpenAI is encapsulated within `ex_cloudflare_service.OpenAI`, implementing the logic to send the request and handle responses in a type safe manner.
    *  The `requestOpenAIService` which is a core function in the Orange code base is now mapped to this service module and its logic.
*  **Code:**
        * The `requestOpenAIService` function maps directly to `ex_cloudflare_service.OpenAI.request_openai_service`.

**5. Orange's `app/utils/rxjs/*`, `app/utils/getUserMedia.ts`, `app/utils/ewma.ts` (State and Media Management Utilities):**
*   **Purpose:** These utilities handle observable based interactions, track state of WebRTC, and provides helper functions to get MediaStream and manage bitrates for peer connections.
*   **Mapping:**
    *  These functions will be rewritten in a more elixir-friendly way, with a mix of functional abstractions, or GenServer for stateful components. However, the core ideas will be ported such as device prioritisation, data reporting, track health, etc.
    *  The device lists, and their sorting will be implemented using functional approaches.
    * The webRTC stream is implemented as a separate module inside the `ex_cloudflare_phoenix` module.
 *  **Code**:
        * The concepts will exist across `ex_cloudflare_phoenix.Media`, `ex_cloudflare_core.sdp`, and potentially inside the `ex_cloudflare_service` if a pattern or framework is needed to interface with external services.

**6. Orange's `app/utils/callsTypes.ts`:**

*   **Purpose:** Defines all the types used in the `calls` code.
*    **Mapping:**
    *   These are translated into Elixir typespecs across the different modules, such as `ex_cloudflare_calls.api`, `ex_cloudflare_calls.session` and `ex_cloudflare_phoenix`.

**Overall Mapping Summary:**

| Orange Component                               | Elixir Package/Module                             | Notes                                                                                                          |
| ---------------------------------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| `server.ts` (main worker)                       | Phoenix app/entrypoint, and `ex_cloudflare_durable`      |  Core logic is in the Phoenix App, Durable object definitions are in  `ex_cloudflare_durable`.                 |
| `ChatRoom.server.ts`                           | `ExCloudflarePhoenix.Behaviours.Room` + `ex_cloudflare_durable.Object`/`Storage`+`ex_cloudflare_calls.Session`|   The core durable object functionality is in ex_cloudflare_durable, combined with Phoenix for state and websocket handling and callbacks    |
| `app/queue.ts`                                 | `ExCloudflareService.Queue`                         |   Will use HTTPoison for now, can add a queue handler abstraction later.                        |
| `app/utils/openai.server.ts`                   | `ExCloudflareService.OpenAI`  |   Implements logic for interacting with OpenAI.                                |
| `app/utils/getUserMedia.ts`, `app/utils/rxjs/*` | `ex_cloudflare_phoenix.Media` + `ex_cloudflare_core.SDP`  |   The core concepts are ported using Elixir idioms. State and lifecycle managment are not in this layer.        |
| `app/utils/callsTypes.ts`                      | Elixir typespecs                                 | Data shapes translated into types for better clarity in Elixir                             |
|`app/mocks/*`| Tests| Mocks will exist in the test folders

**How a Phoenix app will use all of this:**

```elixir
defmodule MyAppWeb.RoomChannel do
  use MyAppWeb, :channel
    import ExCloudflarePhoenix.Components
    
  def join("room:" <> room_name, _params, socket) do
    # fetch room with durable object
    with {:ok, durable_room} <- ExCloudflareDurable.Object.get_namespace(room_name),
         {:ok, calls_session} <- ExCloudflareCalls.new_session(config(:app_id), config(:secret), base_url: "http://localhost:8888")  do
           # track presence
          {:ok, assign(socket, :room, %{id: room_name, durable_room: durable_room, calls_session: calls_session, users: [], ai: %{enabled: false}})} 
          end
      
  end

  def handle_in("userUpdate", data, socket) do
    with {:ok, _} <- update_presence(socket, data) do
         broadcast_room_state(socket)
        {:noreply, socket}
      end
  end
  
   def handle_in("message", payload, socket) do
    case ExCloudflarePhoenix.Behaviours.Room.handle_message(socket.assigns.room, payload) do
         :ok ->
            {:noreply, socket}
          {:error, reason} ->
          Logger.error("Error handling message: #{reason}")
          {:noreply, socket}
        end
    end
end
```
