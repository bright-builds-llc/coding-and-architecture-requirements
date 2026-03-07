# Todo

## Active work

- [x] Remove language-specific installation metadata from the downstream manager and templates
- [x] Rewrite downstream docs and skill wording around a generic install flow
- [x] Preserve migration via `update` for older `AGENTS.md` files while simplifying the CLI surface

## Verification

- [x] `bash -n scripts/manage-downstream.sh` passes
- [x] `./scripts/verify-docs.sh` passes
- [x] Generic install, status, update, uninstall, and uninstall-with-overrides behavior validated in a temp repository
- [x] Unsupported extra CLI options still fail via the default unknown-option path
- [x] Legacy `AGENTS.md` migration via `update` rewrites the file to the new generic format
- [x] Diff reviewed for unintended side effects

## Completion review

Completed on 2026-03-07.

Residual risks:

- The `curl | bash` path still consumes the pinned remote ref, so unpublished local template changes are only exercised when running the script from a local checkout.
