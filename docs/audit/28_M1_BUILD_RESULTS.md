# M1 build results

## Toolchain and command

Local: Visual Studio 2022 Community, x64 MSBuild, `msbuild src/engine-vs2022.sln /p:Configuration=DX11 /m /v:minimal /nologo`. GitHub: `.github/workflows/msbuild.yml`, Windows runner, `build-job (DX11)`.

## Root errors fixed

1. `Actor_Network.cpp` and `xrServer.cpp` had unmatched function scopes (`C1075`), creating many cascading `C2601` errors. The extra braces were removed.
2. Actor input used nonexistent `yaw`/`pitch` members; switched to `unaffected_r_torso`. Server movement flags use `ACTOR_DEFS::` qualification. An obsolete duplicate `M_CL_INPUT` switch case was removed.
3. Linker could not find historical x64 import libraries (`d3dx9.lib`, `nvapi.lib`, `discord_game_sdk.lib`); 67 previously tracked SDK libraries were restored from Git history. Previous M1 CI work had already fixed recursive submodule checkout, Optick revision, and StackWalker.

## Verified runs

| Scope | Commit/run | Result |
| --- | --- | --- |
| Local DX11 before final prediction edit | working tree after server physics correction | Full solution compile/link passed; produced `AnomalyDX11.exe` |
| GitHub ordinary DX11 | run `35896602660`, commit `5756dded1` | Success |
| GitHub other ordinary DX jobs | same run | DX8/9/10/11 and AVX variants success |
| GitHub MT matrix | same run | Checkout failure: missing `all-in-one-vs2022-wpo-mt` ref; other MT jobs canceled |
| Final M1 correctness commit | pending | Update after the next full CI run |

The local link emits preexisting `LNK4006` duplicate Actor symbol warnings: `UIMotionIcon.cpp` includes `actor.cpp`, and the linker discards one copy. This is technical debt despite the successful executable link.
