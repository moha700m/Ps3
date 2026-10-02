# Building the pinned RPCS3 baseline

The emulator source is the official [RPCS3 repository](https://github.com/RPCS3/rpcs3), pinned at commit
`17320679e329908af40b76a8a48c43025d4acc9a` in [`upstream.lock`](../upstream.lock). It is kept unmodified
as the recursive submodule at `upstream/rpcs3`; the commit records its submodule gitlinks. Initialize it
with `git submodule update --init --recursive` before building. The repository's own `AGENTS.md`,
instructions, history, and documentation remain at the root.

## Windows x64 toolchain

The pinned upstream `BUILDING.md` and Windows workflow specify:

- Windows 10 or later, x64, Visual Studio 2022 MSVC (the upstream docs also mention Visual Studio 2026).
- Qt 6.11.2 for MSVC 2022 x64.
- Vulkan SDK 1.4.341.1.
- LLVM 22.1.8.
- CMake 3.28.0 or later if using the CMake build; Visual Studio's integrated CMake is also supported.
- Python 3.6 or later for upstream build steps.

The hosted baseline workflow uses the pinned upstream `.ci/setup-windows.sh` and MSBuild procedure,
with dependency versions/checksums from the pinned upstream `.github/workflows/rpcs3.yml`. It does not
publish to RPCS3 repositories or use RPCS3 release secrets.

## Reproduce the upstream Release build

From a Visual Studio Developer PowerShell opened at the repository root:

```powershell
git submodule update --init --recursive
cd upstream/rpcs3
nuget restore rpcs3.sln
msbuild rpcs3.sln /p:Configuration=Release /p:Platform=x64 /p:PreferredToolArchitecture=x64 /v:minimal
```

The upstream solution and its CI setup scripts may require the versions and environment variables
documented in the pinned `upstream/rpcs3/BUILDING.md` and `upstream/rpcs3/.github/workflows/rpcs3.yml`.
The official Windows CI setup is run by this repository's
[Windows baseline workflow](../.github/workflows/windows-baseline.yml). Its test step runs the upstream
`build/lib/Release-x64/rpcs3_test.exe` when built.

When building with CMake, follow the pinned upstream `BUILDING.md` and explicitly set
`-DUSE_NATIVE_INSTRUCTIONS=OFF` for distributable builds; do not compile only for the build host CPU.
The default upstream settings and required CPU feature level otherwise remain unchanged.

## Verification status and scope

The Actions workflow compiles the unmodified upstream source as a Windows x64 Release and runs the
upstream unit-test executable. A hosted build or unit-test pass does not demonstrate GUI behavior,
GPU/backend compatibility, game boot, performance, physical controller behavior, or a portable
end-user package. Those require separate Windows hardware and user-owned test content. This repository
does not include firmware, games, or license files.

The baseline workflow currently produces an upstream build artifact and SHA-256 for verification;
it is not yet the branded `MohammedLab-PS3-Windows-x64.zip`. Do not treat it as a finished end-user
release until the Qt deployment, branding, portable data paths, runtime checks, and local hardware
tests have been completed.
