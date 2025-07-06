---
sidebar_position: 1
---

# 📖 About

Roblox game framework built to skyroket your developer experience!

## Features

...

## Planned

Below is AI stuff but it covers pretty much everything I'd ever want for this framework (i think)

- Timeouts & Retries
- Regex Subscriptions? (like `Player(HP|MaxHP)Changed`)
- Event Filtering? (deliver event only to those that meet requirements, like is VIP or has certain level or cash, auth hooks)
- Delta-Compression - Send only changed fields instead of the full table/object each tick.
- Prioritized Sync - Critical properties update every frame (or :`Set()`); less‑critical ones less often.
- Snapshot & Interpolation of properties
- Area‑of‑Interest (AOI) Filtering - Automatically only send updates about things near the player.
- Streamed Asset Loading - Tie network sync into Roblox’s streaming service so you don’t update objects that haven’t streamed in yet.
- Rate Limiting & Flood Protection - Throttle clients that fire events too quickly to prevent DDOS/exploits.
- Built‑In Profiler - Track round‑trip times, bandwidth per-remote, calls per-second, etc., surfaced in an in‑game debug UI.
- Bandwidth Budgeting - Set per-player or global limits and receive warnings when you exceed them.
- Plugin API?
- Client Prediction & Reconciliation - Let clients predict movement/animations locally and reconcile when the server corrects them.
- Authoritative Server Logic - Helpers for “optimistic” client calls that get rolled back if the server disagrees.
- Rollback Networking - For fast‑paced games (fighters, racing), rewind/re‑simulate inputs to resolve conflicts fairly. (here maybe kinda the same as snapshot and then rollback)
- Pluggable Codecs - Swap in JSON, MessagePack, Protobuf, or custom bit‑packed formats.
- Optional Encryption - Encrypt particularly sensitive payloads (e.g. for anti‑cheat) over the wire.
- Latency / Packet‑Loss Simulation - Inject arbitrary delay, drop rates or jitter locally so you can test how clients cope under poor network conditions.
- Record & Replay - Capture a sequence of client↔server interactions in a real session, then replay them deterministically for debugging.
- Load‑Testing Harness - Simulate hundreds or thousands of clients firing events and calls to measure your server’s throughput and bottlenecks.
- Multicast / Group Calls - Invoke a function on a specific subset of clients (e.g. team A) with one call.
- Error‑Reporting Integration - Auto‑catch thrown errors in server handlers and forward stack‑traces to a remote DataStore/third‑party (e.g. Sentry‑style) for post‑mortem.
- Transaction / Unit‑Of‑Work API - Let clients bundle multiple calls/properties into one atomic “commit” with rollback on failure.
