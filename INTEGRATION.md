# LAMBO Server Integration Guide

Comprehensive guide for integrating and using LAMBO Server in your applications. This document covers both WebSocket client connections and HTTP API usage.

## Table of Contents

1. [Introduction](#introduction)
2. [Core Concepts](#core-concepts)
3. [Getting Started](#getting-started)
4. [WebSocket Client Integration](#websocket-client-integration)
5. [HTTP API Integration](#http-api-integration)
6. [Message Protocol](#message-protocol)
7. [Code Examples](#code-examples)
8. [Advanced Topics](#advanced-topics)
9. [Configuration](#configuration)
10. [Troubleshooting](#troubleshooting)

---

## Introduction

LAMBO Server is a high-performance WebSocket relay server designed for real-time synchronization between devices and applications. It enables seamless communication in a "Master-Slave" architecture where one client controls state and broadcasts updates to others.

### Primary Use Cases

- **Multi-Device Synchronization**: Keep multiple devices in perfect sync (presentations, displays, gaming setups)
- **Remote Control Systems**: Control connected devices from a central hub
- **Real-Time Collaboration**: Share state across different applications in real-time
- **External Event Triggers**: Trigger actions in connected clients via HTTP requests

---

## Core Concepts

### Rooms

A **Room** is an isolated virtual space identified by a unique code. All devices connecting with the same room code share the same message relay channel.

```
Room Code Examples:
  - meeting-room-A
  - exhibit-01
  - gaming-session-xyz
```

**Key Characteristics:**
- Private and isolated (only connections with matching room code can communicate)
- Automatically cleaned up when the last client disconnects
- Maintains the last "room-state" message for late-joining clients

### Roles

Each connection has a designated role that affects its behavior:

#### Master
- Typically the control/driver device
- Sends state updates and commands
- Usually broadcasts the "room-state" event
- Can have multiple Masters in a room (concurrent updates possible)

#### Slave
- Listener/receiver devices
- Reacts to events from Masters
- Automatically receives the latest room state upon joining
- Can send messages to other clients (server relays them)

### Message Flow

```
Master Device
     ↓ sends event
Server (Room Relay)
     ↓ broadcasts
Slave Devices (react to event)
```

### Late-Joiner Support

When a Slave joins a room, it automatically receives the last cached "room-state" message. This allows new connections to immediately understand the current state without waiting for the next Master update.

---

## Getting Started

### Prerequisites

- LAMBO Server running and accessible (see [Configuration](#configuration) for setup)
- WebSocket support (most modern browsers and frameworks support this)
- Basic understanding of JSON data structures

### Server Information You'll Need

Before connecting, have these details ready:

```
Server Address: (IP or domain)
  Example: localhost, 192.168.1.100, or lambo.example.com

Server Port: (default 8080)
  Example: 8080

Room Code: (your unique session identifier)
  Example: my-room-123
  Allowed characters: a-z, A-Z, 0-9, hyphen (-), underscore (_)

Role: (master or slave)
```

### Basic Connection Flow

1. **Determine Role**: Decide if this client should be Master or Slave
2. **Choose/Share Room Code**: Create or join an existing room
3. **Connect via WebSocket**: Open connection to the server
4. **Send/Receive Messages**: Communicate using the message protocol
5. **Handle Disconnections**: Implement reconnection logic

---

## WebSocket Client Integration

### Connection URL Format

```
ws://<server-address>:<port>/ws/pcautomation/<room-code>?role=<master|slave>
```

**Parameters:**
- `<server-address>`: IP or domain of LAMBO Server
- `<port>`: Server port (default: 8080)
- `<room-code>`: Unique identifier for the room
- `<master|slave>`: Client role (lowercase)

### Connection Examples

**WebSocket as Master:**
```
ws://localhost:8080/ws/pcautomation/my-room?role=master
```

**WebSocket as Slave (Remote Server):**
```
ws://192.168.1.100:8080/ws/pcautomation/presentation-1?role=slave
```

### Connection Lifecycle

#### Establishing Connection

```javascript
const socket = new WebSocket('ws://localhost:8080/ws/pcautomation/my-room?role=master');

socket.onopen = () => {
  console.log('Connected to LAMBO Server');
};

socket.onerror = (error) => {
  console.error('Connection error:', error);
};

socket.onclose = () => {
  console.log('Disconnected from LAMBO Server');
};
```

#### Sending Messages

```javascript
const message = {
  event: 'update-state',
  payload: {
    timestamp: Date.now(),
    data: { /* your data */ }
  }
};

socket.send(JSON.stringify(message));
```

#### Receiving Messages

```javascript
socket.onmessage = (event) => {
  const message = JSON.parse(event.data);
  console.log('Event:', message.event);
  console.log('Payload:', message.payload);
  
  // Handle different event types
  switch(message.event) {
    case 'room-state':
      handleRoomState(message.payload);
      break;
    case 'update':
      handleUpdate(message.payload);
      break;
    default:
      handleCustomEvent(message.event, message.payload);
  }
};
```

### Handling Disconnections

**Automatic Heartbeat:**
The server sends periodic ping messages to detect stale connections. Clients should respond with pong.

**Reconnection Logic:**
```javascript
let socket;
const MAX_RETRIES = 5;
let retryCount = 0;

function connect() {
  socket = new WebSocket('ws://localhost:8080/ws/pcautomation/my-room?role=master');
  
  socket.onopen = () => {
    retryCount = 0; // Reset on successful connection
  };
  
  socket.onclose = () => {
    if (retryCount < MAX_RETRIES) {
      retryCount++;
      setTimeout(connect, 1000 * retryCount); // Exponential backoff
    }
  };
}

connect();
```

---

## HTTP API Integration

### Use Cases

The HTTP API is useful when:
- An external service needs to trigger events in a room
- You don't want to maintain a persistent WebSocket connection
- Integrating webhooks or cron jobs
- Simple one-off event triggers

### HTTP POST Endpoint

```
POST /api/event/<room-code>/<event-name>
Content-Type: application/json

{
  "payload": { /* your data */ }
}
```

**URL Parameters:**
- `<room-code>`: Target room identifier
- `<event-name>`: Name of the event to trigger

### HTTP Examples

**cURL Example:**
```bash
curl -X POST http://localhost:8080/api/event/my-room/play-video \
  -H "Content-Type: application/json" \
  -d '{"payload": {"url": "video.mp4", "timestamp": 0}}'
```

**Python Example:**
```python
import requests
import json

room_code = "my-room"
event_name = "play-video"
url = f"http://localhost:8080/api/event/{room_code}/{event_name}"

payload = {
  "payload": {
    "url": "video.mp4",
    "timestamp": 0
  }
}

response = requests.post(url, json=payload)
print(response.status_code)
```

**Node.js Example:**
```javascript
const http = require('http');

const options = {
  hostname: 'localhost',
  port: 8080,
  path: '/api/event/my-room/play-video',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  }
};

const req = http.request(options, (res) => {
  console.log(`Status: ${res.statusCode}`);
});

req.write(JSON.stringify({
  payload: {
    url: 'video.mp4',
    timestamp: 0
  }
}));
req.end();
```

---

## Message Protocol

### Message Structure

All messages follow the same JSON structure:

```json
{
  "event": "event-name",
  "payload": {
    "key1": "value1",
    "key2": 123,
    "nested": {
      "key3": true
    }
  }
}
```

**Fields:**
- `event` (string, required): Identifies the type of message/action
- `payload` (object): Data associated with the event (can be empty `{}`)

### Validation Rules

**Event Name:**
- Must be a non-empty string
- Recommended format: lowercase with hyphens (`play-video`, `update-state`)
- Maximum length: 255 characters

**Payload:**
- Must be a valid JSON object
- Can contain any valid JSON types: strings, numbers, booleans, arrays, objects
- Empty payload is allowed: `{}`

### Reserved Events

#### `room-state`
Sent by the server automatically when a client joins. Contains the last known state.

```json
{
  "event": "room-state",
  "payload": {
    "current-state": { /* latest state data */ }
  }
}
```

#### `connection`
Server notification about connection status.

```json
{
  "event": "connection",
  "payload": {
    "status": "connected"
  }
}
```

### Custom Events

Define your own event names for application-specific communication:

```json
{
  "event": "play-video",
  "payload": {
    "videoId": "abc123",
    "timestamp": 42.5
  }
}
```

```json
{
  "event": "update-position",
  "payload": {
    "x": 100,
    "y": 200,
    "rotation": 45
  }
}
```

---

## Code Examples

### JavaScript / Node.js WebSocket Client

**Complete Master Client:**
```javascript
class LamboMasterClient {
  constructor(serverUrl, roomCode) {
    this.serverUrl = serverUrl;
    this.roomCode = roomCode;
    this.socket = null;
  }

  connect() {
    const url = `ws://${this.serverUrl}/ws/pcautomation/${this.roomCode}?role=master`;
    this.socket = new WebSocket(url);

    this.socket.onopen = () => {
      console.log('Connected as Master');
      this.sendRoomState();
    };

    this.socket.onmessage = (event) => {
      const message = JSON.parse(event.data);
      console.log('Received:', message.event, message.payload);
    };

    this.socket.onerror = (error) => {
      console.error('WebSocket error:', error);
    };

    this.socket.onclose = () => {
      console.log('Disconnected');
      setTimeout(() => this.connect(), 3000);
    };
  }

  sendRoomState() {
    this.send('room-state', {
      state: 'initialized',
      timestamp: Date.now()
    });
  }

  send(eventName, payload) {
    if (this.socket.readyState === WebSocket.OPEN) {
      this.socket.send(JSON.stringify({
        event: eventName,
        payload: payload
      }));
    }
  }

  disconnect() {
    if (this.socket) {
      this.socket.close();
    }
  }
}

// Usage
const client = new LamboMasterClient('localhost:8080', 'my-room');
client.connect();

setTimeout(() => {
  client.send('update-state', { active: true, count: 5 });
}, 1000);
```

**Complete Slave Client:**
```javascript
class LamboSlaveClient {
  constructor(serverUrl, roomCode, eventHandler) {
    this.serverUrl = serverUrl;
    this.roomCode = roomCode;
    this.eventHandler = eventHandler;
    this.socket = null;
  }

  connect() {
    const url = `ws://${this.serverUrl}/ws/pcautomation/${this.roomCode}?role=slave`;
    this.socket = new WebSocket(url);

    this.socket.onopen = () => {
      console.log('Connected as Slave');
    };

    this.socket.onmessage = (event) => {
      const message = JSON.parse(event.data);
      this.eventHandler(message.event, message.payload);
    };

    this.socket.onclose = () => {
      setTimeout(() => this.connect(), 3000);
    };
  }

  disconnect() {
    if (this.socket) {
      this.socket.close();
    }
  }
}

// Usage
function handleEvent(eventName, payload) {
  console.log(`Event: ${eventName}`, payload);
  
  switch(eventName) {
    case 'room-state':
      console.log('Room state:', payload);
      break;
    case 'play-video':
      console.log('Playing video:', payload.url);
      break;
  }
}

const slaveClient = new LamboSlaveClient('localhost:8080', 'my-room', handleEvent);
slaveClient.connect();
```

### Dart/Flutter Client

```dart
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class LamboClient {
  final String serverUrl;
  final String roomCode;
  final String role;
  late WebSocketChannel channel;
  
  LamboClient({
    required this.serverUrl,
    required this.roomCode,
    required this.role,
  });

  Future<void> connect() async {
    final url = 'ws://$serverUrl/ws/pcautomation/$roomCode?role=$role';
    channel = WebSocketChannel.connect(Uri.parse(url));
    
    channel.stream.listen(
      (message) {
        final data = jsonDecode(message);
        handleMessage(data['event'], data['payload']);
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
      onDone: () {
        print('Disconnected');
      },
    );
  }

  void send(String event, Map<String, dynamic> payload) {
    final message = {
      'event': event,
      'payload': payload,
    };
    channel.sink.add(jsonEncode(message));
  }

  void handleMessage(String event, dynamic payload) {
    print('Received $event: $payload');
    switch(event) {
      case 'room-state':
        // Handle room state
        break;
      default:
        // Handle custom events
    }
  }

  void disconnect() {
    channel.sink.close();
  }
}

// Usage
void main() async {
  final client = LamboClient(
    serverUrl: 'localhost:8080',
    roomCode: 'my-room',
    role: 'master',
  );
  
  await client.connect();
  client.send('update-state', {'timestamp': DateTime.now().millisecondsSinceEpoch});
}
```

### Python Client

```python
import asyncio
import websockets
import json

class LamboClient:
    def __init__(self, server_url, room_code, role='master'):
        self.server_url = server_url
        self.room_code = room_code
        self.role = role
        self.ws = None
        self.running = False

    async def connect(self):
        uri = f'ws://{self.server_url}/ws/pcautomation/{self.room_code}?role={self.role}'
        self.running = True
        
        try:
            self.ws = await websockets.connect(uri)
            print(f'Connected as {self.role}')
            await self.receive_messages()
        except websockets.exceptions.WebSocketException as e:
            print(f'Connection error: {e}')
            self.running = False

    async def receive_messages(self):
        try:
            async for message in self.ws:
                data = json.loads(message)
                await self.handle_message(data['event'], data['payload'])
        except websockets.exceptions.ConnectionClosed:
            print('Connection closed')
            self.running = False

    async def send(self, event, payload):
        if self.ws:
            message = {
                'event': event,
                'payload': payload
            }
            await self.ws.send(json.dumps(message))

    async def handle_message(self, event, payload):
        print(f'Received {event}: {payload}')
        
        if event == 'room-state':
            print(f'Room state: {payload}')
        elif event == 'update':
            print(f'Update received: {payload}')

    async def disconnect(self):
        self.running = False
        if self.ws:
            await self.ws.close()

# Usage
async def main():
    client = LamboClient('localhost:8080', 'my-room', 'master')
    await client.connect()

if __name__ == '__main__':
    asyncio.run(main())
```

---

## Advanced Topics

### Late-Joiner Recovery

When a Slave connects to an active room, it automatically receives the last cached "room-state" message. This allows immediate understanding of current state.

**Implementation Example:**
```javascript
let currentRoomState = null;

socket.onmessage = (event) => {
  const message = JSON.parse(event.data);
  
  if (message.event === 'room-state') {
    // Store the latest state for new clients
    currentRoomState = message.payload;
    updateUIWithState(message.payload);
  }
};
```

**Master Broadcasting State:**
```javascript
function updateMasterState(newState) {
  // Broadcast state so all Slaves (and future joiners) see it
  client.send('room-state', newState);
  
  // Send specific event for immediate notification
  client.send('state-changed', { change: newState });
}
```

### Rate Limiting

LAMBO Server enforces a **50 messages per second per client** limit to protect system stability.

**Handling Rate Limits:**
```javascript
let messageQueue = [];
let isThrottled = false;

function queueMessage(event, payload) {
  messageQueue.push({ event, payload });
  
  if (!isThrottled) {
    sendQueued();
  }
}

function sendQueued() {
  if (messageQueue.length === 0) {
    isThrottled = false;
    return;
  }
  
  isThrottled = true;
  const msg = messageQueue.shift();
  client.send(msg.event, msg.payload);
  
  setTimeout(sendQueued, 20); // ~50 messages/sec
}
```

### Room Lifecycle

**Room Creation:**
Implicit - created when first client connects with a room code

**Room Cleanup:**
Automatic - deleted when last client disconnects

**Multiple Masters:**
Allowed - multiple Masters can send simultaneous updates

**Message Broadcasting:**
All messages from any client are relayed to all other clients in the room

---

## Configuration

### Environment Variables

**LAMBO_HOST**
- Default: `0.0.0.0` (listen on all interfaces)
- Example: `export LAMBO_HOST=192.168.1.100`

**LAMBO_PORT**
- Default: `8080`
- Example: `export LAMBO_PORT=9000`

**Running with Configuration:**
```bash
LAMBO_HOST=localhost LAMBO_PORT=3000 dart run bin/lambo_server.dart
```

### Docker Deployment

**Build Docker Image:**
```bash
docker build -t lambo-server .
```

**Run Container:**
```bash
docker run -p 8080:8080 lambo-server
```

**With Custom Port:**
```bash
docker run -p 3000:8080 -e LAMBO_PORT=8080 lambo-server
```

### Docker Compose

```yaml
version: '3.8'
services:
  lambo:
    build: .
    ports:
      - "8080:8080"
    environment:
      LAMBO_HOST: "0.0.0.0"
      LAMBO_PORT: "8080"
```

---

## Troubleshooting

### Connection Issues

**Problem:** WebSocket connection fails with "Connection refused"
- **Cause**: Server not running or wrong address/port
- **Solution**: Verify server is running on correct host and port
  ```bash
  curl -I http://localhost:8080/
  ```

**Problem:** Connection works but messages aren't received
- **Cause**: Wrong room code or role configuration
- **Solution**: Verify room code matches between Master and Slave

### Message Issues

**Problem:** "Invalid message format" error
- **Cause**: Malformed JSON or missing required fields
- **Solution**: Ensure message follows structure:
  ```json
  {
    "event": "my-event",
    "payload": {}
  }
  ```

**Problem:** Messages exceed the 50 msg/sec rate limit
- **Cause**: Sending too many messages rapidly
- **Solution**: Implement message queuing or batching

### Connection Drops

**Problem:** Frequent disconnections
- **Cause**: Network instability or server timeout
- **Solution**: 
  - Implement automatic reconnection with exponential backoff
  - Ensure heartbeat/ping responses are sent
  - Check server logs: `dart run bin/lambo_server.dart`

### Debugging Tips

**Enable Logging:**
Review server logs when starting the server:
```bash
dart run bin/lambo_server.dart 2>&1 | grep -E "ERROR|WARN"
```

**Browser DevTools:**
Monitor WebSocket traffic in browser:
- Open DevTools → Network tab
- Filter by "WS" to see WebSocket messages
- Inspect message payloads

**Test Connectivity:**
```bash
# Check if server is reachable
curl -I http://localhost:8080/

# Send HTTP event
curl -X POST http://localhost:8080/api/event/test-room/test-event \
  -H "Content-Type: application/json" \
  -d '{"payload": {"test": true}}'
```

**Common Error Messages:**

| Error | Meaning | Solution |
|-------|---------|----------|
| `event cannot be empty` | Event name is missing or blank | Include non-empty `event` field |
| `Connection refused` | Server not running | Start LAMBO Server |
| `Invalid room code` | Room code has invalid characters | Use only a-z, A-Z, 0-9, -, _ |
| `Rate limit exceeded` | Too many messages sent | Reduce message frequency or implement queuing |

---

## Best Practices

### Architecture

1. **Designate Clear Masters/Slaves**: One Master coordinates, Slaves follow
2. **Idempotent Messages**: Design events so resends don't cause duplicates
3. **State Recovery**: Always broadcast `room-state` for late joiners
4. **Error Handling**: Implement reconnection logic and graceful degradation

### Performance

1. **Batch Updates**: Combine multiple state changes into one message
2. **Compress Payloads**: Send only necessary data
3. **Avoid Polling**: Use events instead of repeated requests
4. **Monitor Rate Limits**: Queue messages intelligently

### Security

1. **Validate Payloads**: Check data types and ranges in received messages
2. **Use Room Codes**: Prevent unauthorized access via room isolation
3. **HTTPS/WSS**: Use TLS in production deployments
4. **Input Validation**: Sanitize all received data before use

---

## Support & Resources

- **GitHub Issues**: Report bugs or request features
- **Server Logs**: Check logs for detailed error information
- **API Reference**: See [Message Protocol](#message-protocol) section
- **Examples**: Review [Code Examples](#code-examples) for language-specific implementations

