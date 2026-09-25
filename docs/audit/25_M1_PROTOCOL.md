# M1 movement protocol (source-verified, 2026-09-24)

Source of truth: `src/xrServerEntities/xrMessages.h`, `src/xrGame/actor_defs.h`, `src/xrGame/Actor_Network.cpp`, `src/xrGame/xrServer.cpp`, and `src/xrGame/Level_network_messages.cpp`. Both peers must use this build because the existing `M_CL_INPUT` payload changed. The ACK ID is appended to the enum, preserving IDs of later legacy messages. There is no protocol version negotiation in M1.

## Client to server: M_CL_INPUT

Enum ID **9**. `NET_Packet::w_begin` adds a 2-byte message ID; payload is exactly **14 bytes**, in order:

| Field | Encoding | Bytes |
| --- | --- | ---: |
| sequence | `u32` | 4 |
| mstate | `u16` | 2 |
| yaw | IEEE 754 `float` | 4 |
| pitch | IEEE 754 `float` | 4 |

The owning client sends this packet reliably through `Level().Send`. No actor ID, absolute position, velocity, or client-controlled timestep is included. The client masks `mstate_real` to `kM1InputIntentFlags`, excluding physics-derived fall, landing, turn and climb flags. It also excludes the persistent local `mcJump` bit and adds jump only for a latched key-press edge; the server validates against the shared intent mask. The server derives ownership from the sender connection and validates the owner type, exact packet length, finite and bounded angles, allowed movement flags, and sequence window. Yaw is normalized; pitch is normalized and clamped to ±π/2. The packet rate does not determine physics step count.

Sequence arithmetic uses unsigned `u32` subtraction: `incoming - previous` must be in `1..0x7fffffff`, and the forward window is limited to 10,000. The server tracks the last valid enqueued sequence separately from the last sequence consumed in simulation. Values wrap from `0xffffffff` to `0`.

## Server to owner: M_CL_INPUT_ACK

Enum ID **53**. Payload is **28 bytes** (30 bytes including message ID): `u32 last_processed_sequence`, `Fvector position` (three floats), `Fvector velocity` (three floats). It is sent with `net_flags(FALSE, TRUE)`: unreliable and newest state wins. The client requires the exact payload length and rejects duplicates, older or future ACKs and non-finite snapshots; a newer ACK removes all acknowledged input/history entries, including when older ACKs were lost.

The position and velocity are captured after the server physics step. Orientation, stance box, and the rest of `CPHMovementControl` state are not in this snapshot; runtime testing must determine whether those fields need explicit authority state.

## Legacy update

The client still exports legacy `M_CL_UPDATE` for non-movement gameplay fields. Its absolute Actor transform is ignored by the server Actor and is never a movement authority. Remote clients receive the existing server `M_UPDATE` entity stream; they do not consume another player's `M_CL_INPUT`.
