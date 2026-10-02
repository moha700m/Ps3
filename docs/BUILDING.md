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
This repository keeps its application changes as reviewable patch files outside the pinned submodule.
To apply the first-run UI patch before a local build:

```bash
(cd upstream/rpcs3 && git apply ../../patches/0001-bilingual-first-run-setup.patch)
```

The repository's [Windows workflow](../.github/workflows/windows-baseline.yml) applies this patch
before building and runs `build/lib/Release-x64/rpcs3_test.exe` from the resulting build.

When building with CMake, follow the pinned upstream `BUILDING.md` and explicitly set
`-DUSE_NATIVE_INSTRUCTIONS=OFF` for distributable builds; do not compile only for the build host CPU.
The default upstream settings and required CPU feature level otherwise remain unchanged.

## Verification status and scope

The [hosted Windows run](https://github.com/moha700m/Ps3/actions/runs/36984899813) successfully built
the unmodified pinned RPCS3 Release x64 source, passed 150 unit tests across 16 test cases, validated
the package SHA-256 and extracted executable/Qt platform plugin, and uploaded a 38.5 MB build archive
and test report. The [build artifact](https://github.com/moha700m/Ps3/actions/artifacts/11219029122)
is a baseline RPCS3 archive, not the final branded ZIP.

The project now carries `patches/0001-bilingual-first-run-setup.patch`. It adds an English/Arabic
quick-setup panel to RPCS3's existing welcome dialog, with buttons wired to the existing firmware
installer, game-folder scanner, and controller settings, plus a basic OS/CPU overview explicitly
marked as non-certifying. The Windows workflow applies this patch before compiling and testing. That
modified build has not yet had a hosted run, and the successful baseline result above does not validate
this patch.

This increment does not yet provide a complete Arabic translation of the emulator UI, full
requirements-based hardware diagnostics, controller connection/button testing, or
`MohammedLab-PS3-Windows-x64.zip`. The baseline artifact also does not validate extracted-user
execution, runtime dependencies, writable portable data paths, or matching-source release packaging.
A hosted build/unit-test pass does not demonstrate GUI behavior, GPU/backend compatibility, game boot,
performance, or physical-controller behavior; those need separate Windows hardware and user-owned
test content. Firmware, games, and license files are not included in this repository or CI.
