# M1 build results

## Toolchain and command

Local: Visual Studio 2022 Community, x64 MSBuild, `msbuild src/engine-vs2022.sln /p:Configuration=DX11 /m /v:minimal /nologo`. GitHub: `.github/workflows/msbuild.yml`, Windows runner, `build-job (DX11)`.

## Root errors fixed

1. `Actor_Network.cpp` and `xrServer.cpp` had unmatched function scopes (`C1075`), creating many cascading `C2601` errors. The extra braces were removed.
2. Actor input used nonexistent `yaw`/`pitch` members; switched to `unaffected_r_torso`. Server movement flags use `ACTOR_DEFS::` qualification. An obsolete duplicate `M_CL_INPUT` switch case was removed.
3. Linker could not find historical x64 import libraries (`d3dx9.lib`, `nvapi.lib`, `discord_game_sdk.lib`); 67 previously tracked SDK libraries were restored from Git history. Previous M1 CI work had already fixed recursive submodule checkout, Optick revision, and StackWalker.
4. A later runtime diagnostics change made static `CScriptStorage::script_log` call the non-static `print_stack` directly (`C2352`); it was restored to the global script engine call after dedicated AI/Lua initialization was added. The next run compiled and linked all ordinary configurations.

## Verified runs

| Scope | Commit/run | Result |
| --- | --- | --- |
| Local DX11 before final prediction edit | working tree after server physics correction | Full solution compile/link passed; produced `AnomalyDX11.exe` |
| GitHub ordinary DX11 | run `35896602660`, commit `5756dded1` | Success |
| GitHub other ordinary DX jobs | same run | DX8/9/10/11 and AVX variants success |
| GitHub MT matrix | same run | Checkout failure: missing `all-in-one-vs2022-wpo-mt` ref; other MT jobs canceled |
| Last green source commit before runtime diagnostics fix, `316db1a3f` | GitHub run `35995955085` | DX11 and all seven other ordinary DX jobs succeeded; `pack_gamedata` succeeded |
| Final MT matrix | GitHub run `35995955085` | All eight jobs failed during checkout of missing `all-in-one-vs2022-wpo-mt`; no MT compiler result |
| Runtime diagnostics commit `1cb4bf2ce` | GitHub run `35999470671` | Failed to compile: `CScriptStorage::script_log` static/non-static call (`C2352`) |
| Dedicated Lua initialization and compile correction, `10df37c24` | GitHub run `36001493151` | DX11 and all seven other ordinary DX jobs succeeded; `pack_gamedata` succeeded |
| Dedicated loading UI guard, `38cd3aedb` | GitHub run `36004660989` | DX11 and all seven other ordinary DX jobs succeeded; `pack_gamedata` succeeded |
| Dedicated console render callback guard, `4afc4c177` | GitHub run `36029832194` | Seven ordinary DX jobs succeeded; DX11 failed before compilation in the pagefile setup action (`exit code 'null'`); a matching local DX11 full solution compiled and linked |
| Dedicated Actor AI location, `1d116f245` | GitHub run `36033438764` | DX11 and all seven other ordinary DX jobs succeeded; MT jobs failed before compilation on missing branch |
| Dedicated map/PDA state, `84b008049` | GitHub run `36035156315` | DX11 and all seven other ordinary DX jobs succeeded; MT jobs failed before compilation on missing branch |
| Current runtime smoke source, `3bc288e7c` | Local full solution DX11 | Compile/link success; SHA-256 `9244C6C2C9CCB9281A56FC95E654A9FF0324BF8EA499EA00D9D4289B4BE5E1A9` |
| Dedicated runtime smoke source, `3bc288e7c` | GitHub run `36037355085` | DX11 and all seven other ordinary DX jobs succeeded; MT jobs failed before compilation on the missing branch |
| Separate dedicated/client packaging, `926930ec9` | Local full solution DX11 | Compile/link success; the two packaged EXEs share SHA-256 `84CECE72F8722663E347FDE1E83257C0626D7AE4DFCDC91F6F4D371A214EC147` |
| Player-state handshake correction, `25162fb5e` | GitHub run `36147237120` | DX11 and all seven other ordinary DX jobs succeeded; DX11 dedicated/client package and PDB artifacts uploaded. The overall run is failed because the eight MT jobs still check out a nonexistent `all-in-one-vs2022-wpo-mt` branch. |

The matching `316db1a3f` `DX11_exe` artifact was downloaded from run `35995955085`; `AnomalyDX11.exe` SHA-256 is `E8B5F2B7F1CFF69F9E391246BF115CCAC87127FF2C90FAE42AEE2DB02C37D616`. Later local VS2022 full solution DX11 builds passed through `926930ec9`. The final `25162fb5e` source was compiled and linked by GitHub Actions; its packaged CI executable SHA-256 is `CAAB62634F43A380722E3755AB7876BF1CE76A21A8AD9BE043D2BEA2BF173607` for both role-specific copies. That exact package was used for the latest server/client smoke run. The `dedicated` and `bin` EXEs share engine bytes but have different basenames and startup roles; this is not yet a separate dedicated compile target.

The local link emits preexisting `LNK4006` duplicate Actor symbol warnings: `UIMotionIcon.cpp` includes `actor.cpp`, and the linker discards one copy. This is technical debt despite the successful executable link.
