# Lambo Server: Gemini CLI Context

This document provides foundational mandates, architectural patterns, and development workflows for the Lambo Server project.

## Project Overview
Lambo Server is a Dart-based WebSocket relay server for real-time device synchronization using a "Master-Slave" architecture. It organizes connections into "Rooms" where messages from one client (usually a Master) are broadcast to others (Slaves).

## Architectural Patterns
- **Room-based Isolation**: Each room is managed by a `LamboRoom` instance, maintaining its own list of connected `LamboClientModel` members.
- **Stateful Synchronization**: The server caches the last "room-state" message in each room. When a new Slave joins, they are immediately updated with this cached state.
- **Structural Encapsulation**: The core logic is encapsulated in the `LamboServer` class (`lib/lambo_server_core.dart`).
- **JSON Protocol**: All communication uses the `MessageModel` structure:
  - `event_type`: Categorizes the message (e.g., `room-state`, `connection`, `default`).
  - `event`: Specific action or command name.
  - `args`: Positional arguments.
  - `kwargs`: Named arguments/data payload.

## Core Components
- `bin/lambo_server.dart`: Entry point. Simple wrapper for `LamboServer`.
- `lib/lambo_server_core.dart`: Manages `HttpServer` lifecycle, room registry, and request routing.
- `lib/lambo_room.dart`: Manages room members, broadcasting logic, and automatic cleanup.
- `lib/message_model.dart`: Data model for standardized server/client communication with validation and robust parsing.

## Robustness & Security
- **Heartbeat**: Uses `pingInterval` to detect and close stale WebSocket connections.
- **Room Cleanup**: Rooms are automatically deleted when the last member departs.
- **Rate Limiting**: Per-client rate limit of 50 messages per second.
- **Validation**: Strict regex-based validation for room codes and required message fields.

## Development Guidelines
- **Adding Events**: Handle new event types in the `_onMessage` method in `lib/lambo_server_core.dart`.
- **Testing**:
  - Run `dart test` for all unit and integration tests.
  - New features MUST include corresponding tests in the `test/` directory.
- **Logging**: Use the `logger` package. Contextual logs include room codes and client info.

## Key Workflows
- **Running the Server**: `dart run bin/lambo_server.dart`
- **Testing**: `dart test`
- **Configuration**: Port and host can be configured via `LAMBO_PORT` and `LAMBO_HOST` environment variables.
- **Docker**: Build with `docker build -t lambo-server .` and run with `docker run -p 8080:8080 lambo-server`.
