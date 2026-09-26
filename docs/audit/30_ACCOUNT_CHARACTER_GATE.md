# Account and character gate: implementation boundary

The requested player flow is registration or login, then character creation or selection, then entry into the world. A transport connection is not permission to receive world state or own an Actor.

## Current state (2026-09-26)

`xrServer::OnCL_Connected` currently sends the world through `SendConnectionData`, and `game_sv_Single::OnPlayerConnectFinished` spawns a co-op Actor as soon as the normal client-ready packet arrives. The only identity at this point is the connection and a player name. There is no durable account or selected character in the engine protocol. The legacy GameSpy account code is not integrated into this path.

The local `gamma-runtime/services` prototype has SQLite accounts, salted PBKDF2 password hashes, role audit, single-account sessions, and account-scoped player snapshots. It has no remote password-safe transport, no native engine adapter, no multi-character schema and no game UI. Its one-time ticket helper stages files on the same computer, so it is not a remote registration system. Do not call this prototype a completed account feature. The helper's dedicated EXE path was updated to `gamma-runtime/dedicated/AnomalyGammaNetServerDX11.exe`.

The existing `M_SECURE_MESSAGE` uses a key derived from a seed transmitted on the game connection and is not suitable for credentials. Neither passwords nor reusable password verifiers may be carried in these packets. The legacy remote-admin channel is also not the new account role system.

## Required server states

1. `ConnectedUnauthenticated`: bounded handshake only; no world export, no Actor, no gameplay packets.
2. `Authenticated`: server binds a stable account ID to this exact transport connection; duplicate login policy is enforced.
3. `SelectingCharacter`: server returns only characters belonging to that account. Creation validates name, slot limits and starting data and commits atomically.
4. `WorldReady`: a selected character ID is bound to the connection before world replication and Actor spawn. Movement, inventory and later gameplay handlers require this state.
5. `Disconnected`: clear connection auth, character lease, input queue and transient tickets; persist the server-owned character state.

The client must show registration/login and character selection while in the first three states. The client cannot choose an arbitrary Actor ID or character owner. Reconnect loads the selected character once and prevents two live connections from controlling it.

## Credential and storage design

Use an authenticated encrypted channel with validated server identity for registration/login (TLS or equivalent). Pin or validate the server certificate in the client UI. Issue a short-lived session proof for the game connection and bind it to a fresh server challenge and that exact connection; reject replay. Rate-limit registration and failed login per source and per account. Store password hashes with a memory-hard KDF and per-account salt; migrate the prototype's PBKDF2 records deliberately. Never log passwords, proofs or session secrets.

Add `characters(id, account_id, name, created_at, last_location, ...)`, with a foreign key and unique name policy. Character snapshots, inventory item ownership, quests, spawn location and revision belong to character ID, not account ID. Use transactions for creation, save and transfers. Roles remain attached to account ID. Only the local dedicated console may grant or revoke `admin`, and every administrative action must recheck the server-side role and produce an audit record. User registration always creates `player`.

## Integration points

- Add dedicated auth/character message IDs and bounded readers in `xrMessages.h`, `xrServer::OnMessage` and `CLevel::ClientReceive`.
- Gate `xrServer::OnCL_Connected`, `SendConnectionData`, `M_CLIENTREADY`, and `game_sv_Single::OnPlayerConnectFinished` on selected-character state; preserve the local authoritative host bootstrap separately.
- Bind the selected character to `xrClientData` and use that binding when spawning and persisting its Actor.
- Add the registration/login and character screens to the real GAMMA main menu. The normal game start button must remain disabled until selection succeeds.
- Package the dedicated account service, database migrations, trust material and client UI alongside the exact engine build. Test two clients on separate machines, reconnect, concurrent login, replay, wrong password, role grants/revokes, crash recovery and migration.

This is a distinct architecture feature. M1's movement authority fixes do not imply that this gate already exists.
