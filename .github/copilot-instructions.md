# Copilot implementation instructions

Read /AGENTS.md and /docs/IMPLEMENTATION_TASK.md. Implement that task in moha700m/Ps3.

Start with a pinned official RPCS3 source import and a successful Windows Release baseline. Preserve repository documentation, upstream licenses and tests. Then add the Arabic/English first-run setup, hardware diagnostics, supported controller setup and portable packaging incrementally.

Target compatible Windows PCs generally; never hardcode the owner's hardware. Validate real outcomes and explicitly separate hosted CI checks from GPU/game/physical-controller verification.

Open a PR in this repository. No automated communication to upstream RPCS3.
