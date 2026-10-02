# Building the pinned RPCS3 baseline

The emulator source is the official [RPCS3 repository](https://github.com/RPCS3/rpcs3), pinned at commit
`17320679e329908af40b76a8a48c43025d4acc9a` in [`upstream.lock`](../upstream.lock). It is kept unmodified
as the recursive submodule at `upstream/rpcs3`; the commit records its submodule gitlinks. Initialize it
with `git submodule update --init --recursive` before building. The repository's own `AGENTS.md`,
instructions, history, and documentation remain at the root.

## Windows x64 toolchain

The pinned upstream `BUILDING.md` and Windows workflow specify:

- Windows 10 or later, x64, Visual Studio 2026 MSVC (18.x), matching the pinned upstream Windows CI runner.
- Qt 6.11.2 for the MSVC 2022 x64 ABI package, as selected by upstream CI; this is distinct from the VS2026 compiler toolset.
- Vulkan SDK 1.4.341.1.
- LLVM 22.1.8.
- CMake 3.28.0 or later if using the CMake build; Visual Studio's integrated CMake is also supported.
- Python 3.6 or later for upstream build steps.

The hosted baseline workflow uses the `windows-2025-vs2026` runner and explicitly selects MSBuild
from Visual Studio 18.x. It records the selected compiler, linker, and MSVC STL versions before
building. This matches the pinned upstream `.github/workflows/rpcs3.yml`; it also uses the pinned
upstream `.ci/setup-windows.sh` and dependency versions/checksums. It does not publish to RPCS3
repositories or use RPCS3 release secrets.

## Reproduce the upstream Release build

From a Visual Studio 2026 Developer PowerShell opened at the repository root:

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

The [hosted Windows run](https://github.com/moha700m/Ps3/actions/runs/36959767086) for the pinned
source and VS2026 toolchain completed the unmodified upstream Release build and passed 150 unit tests
across 16 test cases. Its package step failed during SHA-256 verification, so no binary artifact was
uploaded from that run. The workflow now uses POSIX-normalized paths for GNU `sha256sum`, validates
the digest format and CR/LF handling, checks both the original and copied archive against the original
checksum, and runs Windows-backslash/path-with-spaces/CRLF and 7z path-separator regression fixtures.
The packaging correction still needs a successful hosted run. A hosted build or unit-test pass does
not demonstrate GUI behavior,
GPU/backend compatibility, game boot, performance, physical controller behavior, or a portable
end-user package. Those require separate Windows hardware and user-owned test content. This repository
does not include firmware, games, or license files.

The baseline workflow is configured to produce an upstream build archive and SHA-256 only after
checking that the archive exists, its checksum matches, and it contains the executable and Qt
Windows platform plugin. The packaging verification correction itself still needs a new hosted run.
This baseline is not the branded
`MohammedLab-PS3-Windows-x64.zip`. Qt deployment validation, branding, portable data paths, runtime
checks, and local hardware tests are still required before an end-user release.
