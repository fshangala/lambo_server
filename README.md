# Lambo Server

Lambo Server is a Dart-based WebSocket server designed to facilitate real-time synchronization between devices. It enables a "Master-Slave" architecture where actions performed on a master device are broadcasted to and replicated on connected slave devices within the same room.

## Overview

The server manages distinct rooms identified by unique room codes. Devices connect to a specific room using its code. Once connected, the server acts as a relay, broadcasting JSON messages received from one client (typically the master) to all other clients (slaves) in that room.

## Features

-   **Room-based Connectivity**: Devices join isolated sessions using a unique room code in the URL.
-   **WebSocket Communication**: Uses standard WebSockets for low-latency, bidirectional communication.
-   **JSON Protocol**: Messages are exchanged as JSON text, making it easy to structure commands and data.
-   **Broadcasting**: Messages sent by a client are broadcast to other members of the room to ensure synchronization.

## Getting Started

### Prerequisites

-   Dart SDK

### Installation

1.  Clone the repository.
2.  Install dependencies:
    ```bash
    dart pub get
    ```

### Running the Server

To start the server, run the following command from the project root:

```bash
dart run bin/lambo_server.dart
```

The server will start listening on `0.0.0.0:8080`.

## Usage

### Connecting

Clients should connect via WebSocket to the following URL pattern:

```
ws://<server-ip>:8080/ws/pcautomation/<room-code>
```

-   `<server-ip>`: The IP address of the machine running Lambo Server.
-   `<room-code>`: A unique string identifier for the room (e.g., `my-room`, `12345`).

### Protocol

The server expects messages in JSON format. When a client sends a message (e.g., a command from the Master), the server parses it and broadcasts it to the room so Slave devices can react accordingly.
