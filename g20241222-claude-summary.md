Durable Objects
SERVER→DO: Create/Get ChatRoom instance with room ID and env bindings
SERVER→DO: Store room state (users, messages, peak count)
SERVER→DO: Read room state for new connections
SERVER→DO: Update user presence and track states
SERVER→DO: Handle WebSocket connections and message broadcasting
CLIENT→DO: Connect to room via WebSocket upgrade
CLIENT→DO: Send/Receive messages through WebSocket
CLIENT→DO: Update user state (camera, mic, screen share status)
Cloudflare Calls API
SERVER→CALLS: Create new session with app credentials
SERVER→CALLS: Create third-party session for AI integration
SERVER→CALLS: Add/Remove tracks to sessions
SERVER→CALLS: Handle SDP offer/answer exchange
CLIENT→CALLS: Get ICE candidates and establish connection
CLIENT→CALLS: Manage media tracks (audio/video)
CLIENT→CALLS: Handle track subscriptions and unsubscriptions
CLIENT→CALLS: Process renegotiation when tracks change
TURN Server
SERVER→TURN: Create TURN credentials for client authentication
SERVER→TURN: Manage TURN key lifecycle
CLIENT→TURN: Request ICE servers configuration
CLIENT→TURN: Establish peer connections using TURN servers
CLIENT→TURN: Fallback to TURN relay when direct connection fails
External Services
SERVER→OPENAI: Send SDP offer for AI voice generation
SERVER→OPENAI: Receive SDP answer with AI-generated audio
SERVER→FEEDBACK: Send feedback messages to external URL
SERVER→USERDIRECTORY: Authenticate and retrieve user information
CLIENT→OPENAI: Stream audio data for processing
CLIENT→OPENAI: Receive AI-generated responses
Queue Processing
//SERVER→QUEUE: Process feedback messages
//SERVER→QUEUE: Handle background tasks
//CLIENT→QUEUE: Submit feedback through API endpoint

SERVER→QUEUE: Enqueue feedback message in ChatCard format
QUEUE→EXTERNAL: POST message to configured FEEDBACK_URL
QUEUE→RETRY: Auto-retry failed message deliveries
CLIENT→SERVER: Submit feedback that gets queued
QUEUE→LOGGING: Log messages when FEEDBACK_URL not configured


