# Lambo Server

Lambo Server is a robust, Dart-based WebSocket relay server designed for real-time device synchronization using a "Master-Slave" architecture. It facilitates seamless communication within isolated "Rooms," where actions from a master device are broadcasted to connected slaves.

## Features

- **Room-based Connectivity**: Isolated sessions identified by unique room codes.
- **Master-Slave Relay**: Efficiently broadcasts JSON messages from masters to slaves.
- **Stateful Sync**: Automatically caches the last "room-state" and delivers it to late-joining slaves.
- **Automatic Lifecycle Management**: 
    - **Room Cleanup**: Empty rooms are automatically pruned to reclaim memory.
    - **Heartbeat**: Built-in ping/pong mechanism to detect and close stale connections.
- **Reliability & Security**:
    - **Rate Limiting**: Protects the server with a per-client limit (default 50 msg/s).
    - **Validation**: Strict validation for room codes and message structures.
    - **Reachability Check**: Supports `HEAD /` for quick server status verification.
- **HTTP Event API**: Trigger events in a room via standard HTTP POST requests.
- **Docker Ready**: Includes a multi-stage Dockerfile for minimal production images.

## Getting Started

### Prerequisites

- [Dart SDK](https://dart.dev/get-dart)
- [Docker](https://www.docker.com/) (optional, for containerized deployment)

### Installation

1. Clone the repository.
2. Install dependencies:
   ```bash
   dart pub get
   ```

### Configuration

The server can be configured using environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `LAMBO_HOST` | The host address to bind to | `0.0.0.0` |
| `LAMBO_PORT` | The port to listen on | `8080` |

### Running the Server

**Locally:**
```bash
dart run bin/lambo_server.dart
```

**With Docker:**
```bash
docker build -t lambo-server .
docker run -p 8080:8080 -e LAMBO_PORT=8080 lambo-server
```

## Testing

The project uses the official Dart `test` package. To run all unit and integration tests:

```bash
dart test
```

## Protocol

### Connection URL
Clients connect via WebSocket using the following pattern:
```
ws://<server-ip>:8080/ws/pcautomation/<room-code>?role=<master|slave>
```
- `<room-code>`: Must match `^[a-zA-Z0-9_-]+$`.
- `role`: Defaults to `slave` if omitted.

### Message Format
Messages must be valid JSON strings following this structure:
```json
{
  "event": "string",
  "payload": { "key": "value" }
}
```
- `event`: Use `room-state` for messages that should be cached for late joiners.

### HTTP API

#### Reachability Check
- **Endpoint**: `/`
- **Method**: `HEAD`
- **Success Response**: `200 OK`

#### Broadcast Event
- **Endpoint**: `/api/event/<room-code>/<event-name>`
- **Method**: `POST`
- **Body**: JSON payload for the event.
- **Example**:
  ```bash
  curl -X POST http://localhost:8080/api/event/my-room/click -d '{"foo": "bar"}'
  ```
- **Responses**:
    - `200 OK`: Event broadcasted successfully.
    - `404 Not Found`: Room code does not exist.
    - `400 Bad Request`: Invalid room code, path, or payload.
