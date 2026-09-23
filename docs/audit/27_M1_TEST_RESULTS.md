# M1 test results (2026-09-23)

## Build evidence

- GitHub Actions run `35896602660`, commit `5756dded1`: `build-job (DX11)` succeeded. All eight ordinary DX build jobs succeeded. This commit includes M1 syntax/compiler fixes and restored x64 SDK import libraries, but predates the later correctness changes.
- Local Visual Studio 2022 `engine-vs2022.sln /p:Configuration=DX11`: passed after the server movement correction pass, before the final prediction-history edit. See `28_M1_BUILD_RESULTS.md` for the final verified commit and run.
- The `build-mt` matrix failed at checkout of the nonexistent `all-in-one-vs2022-wpo-mt` branch. No MT compiler result was produced by that run.

## Source review

Confirmed in source: sender-derived ownership; Actor entity validation; finite input angles; bounded queue; wrap-safe sequence window; stale input timeout; server tick duration; one server-side Actor physics call per schedule tick; post-physics ACK; client position rejection; ACK ordering; prediction restore/replay path; spawn and disconnect reset; existing remote interpolation path.

## Runtime

Dedicated boot, two-client movement, collision, jump, crouch, speed, prediction correction, packet loss/reordering, teleport/ownership attacks and reconnect remain unverified until the bundled GAMMA runtime can execute the new binaries with matching resources. Compile success does not establish physics or headless correctness. Execute the cases in `29_M1_RUNTIME_TEST_PLAN.md` and record logs, positions, sequences, and build hashes.
