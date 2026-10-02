# Repository instructions

This repository is moha700m/Ps3. Build MohammedLab PS3 as a source-built, independently maintained RPCS3 derivative for compatible Windows PCs.

## Required reading
Read docs/IMPLEMENTATION_TASK.md before making changes. It is the user-approved implementation brief. Preserve these instructions and this repository's history when importing upstream.

## Workflow
- Work on a development branch and open a PR in this repository.
- Pin the official RPCS3 upstream commit and recursive submodules. Build the unmodified baseline before UI changes.
- Follow the BUILDING.md and CI configuration at the pinned upstream revision; document toolchain versions.
- Keep the existing emulator core and official tests. Use real Qt/emulator integrations.
- No hardware model is required or assumed. Detect capabilities and compare with upstream requirements.
- Avoid build flags tied only to the build host CPU. Keep required upstream CPU instruction requirements intact.
- Native Windows x64 executable and portable ZIP are required; end users do not build source.
- Preserve user settings, saves and caches. Keep rendering and compatibility defaults conservative.
- Do not commit firmware, game dumps, user license files, secrets or large generated binaries.
- Retain upstream copyright, license notices and third-party licenses; ship complete corresponding source with releases.
- Adapt upstream publication destinations and repository checks to this repository. Never send automated communication to RPCS3 upstream.
- Distinguish compilation/unit tests/GUI smoke tests from actual GPU, game and physical-controller tests.
- Report inaccessible dependencies, missing capabilities and unexecuted tests honestly. Never fabricate binaries, CI success, FPS or compatibility results.
- Do not open unrelated PRs, remove required functionality to obtain a green check, or rewrite this repository's existing history.

## Completion
Provide concrete changed files, build/test commands and outcomes, real Actions/artifact URLs when available, and remaining local verification steps.
