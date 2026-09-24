# M1 implementation review (2026-09-23)

## Server path

`xrServer::OnMessage(M_CL_INPUT)` finds the sender's `xrClientData`, checks that its owner is an Actor server entity, validates the fixed input payload and sequence, and enqueues at most 64 commands. `xrClientData::ClearInputState` resets input, sequence and stale-time state at initialization, owner reassignment and disconnect. A 500 ms interval without input neutralizes continuous movement intent. The timeout is a tuning value.

The server-side `CActor::shedule_Update` uses the server's clamped schedule delta. For an Actor owned by a remote connection, it collapses queued intent to the newest state while retaining a jump edge, calls the ordinary Actor controls, orientation, and physics once, then sends an authoritative position/velocity ACK. This path includes netcoop despite its single-player game type. Host-local Actors keep their existing control path. Packet count does not add physics steps.

`CActor::net_Import` drops legacy client Actor updates on the server. That is necessary because server `net_Spawn` marks Actors `Local()`, so an earlier `OnServer() && !Local()` check could still enqueue client transforms. The `M_UPDATE` server export path (`CLevel::ClientSend` → `Objects.net_Export` → `xrServer::Process_update` → server replication) remains the path for remote entity snapshots.

## Owner path

`CActor::net_Export` samples movement state and camera yaw/pitch, assigns a wrap-safe sequence and sends `M_CL_INPUT`. A jump key press is latched until the next input packet so a tap between network sends is represented. The local Actor continues to simulate immediately. Prediction history is recorded beside the actual physics call in `shedule_Update`, with local dt, movement state, computed world-space acceleration and jump impulse. On a valid newer ACK, the client restores position and velocity, removes acknowledged entries and replays remaining physics frames without sending new packets. Replay suppresses collision camera effects and collision event side effects in `g_Physics`.

## Remote path and limitations

Other clients use the existing `NET`/`NET_A`, `net_Import` and `make_Interpolation` pipeline for server entity updates. This flow, its update cadence, and the server's `CGameObject` Actor proxy on a dedicated server require runtime observation. The server movement step does not call visual animation setup; remote clients animate from replicated state. The snapshot does not include the full character physics state. Sequence-to-frame association is based on the next unsent input sequence; timing at the send/physics boundary requires a two-client test under latency and loss. `g_cl_CheckControls` invokes gameplay and Lua callbacks on the server; headless safety must be verified at runtime.

M2 shooting and damage authority is outside this milestone.
