---
sidebar_position: 1
---

# 📖 About

Roblox networking framework built to skyroket your developer experience!

## Features

...

## Philosophy

...

## Planned Features

- Delta-Compression - Send only changed fields instead of the full table/object each tick. - this should be default in NetProperty - TODO
- Plugin API? or maybe just middlewares?

---

Below is AI stuff but it covers pretty much everything I'd ever want for this framework (i think)

- ~~Snapshot & Interpolation of properties~~ middlewares
- ~~Built‑In Profiler - Track round‑trip times, bandwidth per-remote, calls per-second, etc., surfaced in an in‑game debug UI.~~ NetEvent middleware
- ~~Latency / Packet‑Loss Simulation - Inject arbitrary delay, drop rates or jitter locally so you can test how clients cope under poor network conditions.~~ NetEvent middleware
- ~~Record & Replay - Capture a sequence of client↔server interactions in a real session, then replay them deterministically for debugging. - thats a huge undertaking~~ that could work with Transaction and rollback of NetEvent
- ~~Transaction / Unit‑Of‑Work API - Let clients bundle multiple calls/properties into one atomic “commit” with rollback on failure. - ye i think thats good, not even roblox batching can sometimes saves lots of calls~~ transaction
- ~~Regex Subscriptions? (like `Player(HP|MaxHP)Changed`)~~ object group
- ~~Pluggable Codecs - Swap in JSON, MessagePack, Protobuf, or custom bit‑packed formats.~~ NetEvent middleware
- ~~Timeouts & Retries~~ NetEvent middleware
- ~~Event Filtering? (deliver event only to those that meet requirements, like is VIP or has certain level or cash, auth hooks)~~ user middleware
- ~~Prioritized Sync - Critical properties update every frame (or :`Set()`); less‑critical ones less often.~~ NetEvent middleware for rate limiting
- ~~Area‑of‑Interest (AOI) Filtering - Automatically only send updates about things near the player.~~ NetEvent middleware for AOI
- ~~Rate Limiting & Flood Protection - Throttle clients that fire events too quickly to prevent DDOS/exploits.~~ stated above as NetEvent middleware
- ~~Bandwidth Budgeting - Set per-player or global limits and receive warnings when you exceed them.~~ rate limiting
- ~~Client Prediction & Reconciliation - Let clients predict movement/animations locally and reconcile when the server corrects them.~~ NetEvent middleware
- ~~Authoritative Server Logic - Helpers for “optimistic” client calls that get rolled back if the server disagrees.~~ same as above
- ~~Rollback Networking - For fast‑paced games (fighters, racing), rewind/re‑simulate inputs to resolve conflicts fairly. (here maybe kinda the same as snapshot and then rollback)~~ same as above
- ~~Optional Encryption - Encrypt particularly sensitive payloads (e.g. for anti‑cheat) over the wire.~~ not really needed i think
