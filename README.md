# LAMBO Server

LAMBO Server is a high-performance communication hub designed for real-time synchronization between devices. Using a "Master-Slave" architecture, it allows one device to act as a conductor, instantly broadcasting actions and state changes to all other connected devices in a shared session.

## Core Purpose

The primary use of LAMBO Server is to create "Rooms" where multiple devices can stay in perfect sync. Whether you are building interactive displays, multi-device presentations, or remote-controlled automation systems, LAMBO provides the reliable bridge needed to connect them all.

## Key Features

- **Private Rooms**: Devices connect using a unique room code, ensuring your session is isolated and secure.
- **Instant Synchronization**: Actions performed on a "Master" device are relayed to all "Slave" devices with minimal latency.
- **Late-Joiner Support**: If a new device joins a room already in progress, it automatically receives the latest "room state" so it can catch up immediately.
- **Reliable Connections**: Built-in heartbeats monitor device health and automatically clean up disconnected sessions to keep the system responsive.
- **External Triggers**: Support for standard web requests (HTTP) allows external apps or scripts to trigger events inside a room without needing a persistent connection.

## How It Works

### 1. The Room
A Room is a virtual space identified by a simple code (like `meeting-room-A` or `exhibit-01`). You choose the code when connecting.

### 2. Roles
- **Master**: The controller. Usually, there is one Master that sends commands or state updates.
- **Slave**: The listener. These devices wait for updates from the Master and react accordingly.

### 3. Synchronization
The server acts as a relay. It doesn't just pass messages; it remembers the *last known state* of the room. This ensures that every device, no matter when it connects, sees exactly what everyone else sees.

## Usage Overview

### Connecting Devices
Devices typically connect via a WebSocket URL. Most client applications compatible with LAMBO will ask for:
1.  **Server Address**: The IP or Domain where LAMBO is running.
2.  **Room Code**: Your chosen identifier for the session.
3.  **Role**: Whether this device should control or follow.

### Sending Updates
Messages sent through the server are structured with an **Event Name** (the action) and a **Payload** (the details).
*   *Example Event:* `play-video`
*   *Example Detail:* `{"timestamp": 42.5, "volume": 0.8}`

## System Health
The server is designed for high availability and includes automatic protections against data flooding (Rate Limiting) to ensure that one busy device cannot slow down the experience for others in the same room.
