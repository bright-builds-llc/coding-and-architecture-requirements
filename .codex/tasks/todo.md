# Todo

## Active work

- [x] Add hidden breadcrumb comments to every managed downstream Markdown file
- [x] Add a visible downstream audit manifest with source, pin, and managed-file metadata
- [x] Make install, update, status, and uninstall audit-aware while preserving legacy migration paths

## Verification

- [x] `bash -n scripts/manage-downstream.sh` passes
- [x] `./scripts/verify-docs.sh` passes
- [x] Generic install, status, update, uninstall, and uninstall-with-overrides behavior validated in a temp repository
- [x] Breadcrumb comment markers verified in all rendered downstream Markdown files
- [x] Legacy `AGENTS.md` and existing `standards-overrides.md` migration path validated
- [x] Unsupported extra CLI options still fail via the default unknown-option path
- [x] Diff reviewed for unintended side effects

## Completion review

Completed on 2026-03-12.

Residual risks:

- The audit manifest retention on default uninstall is intentional, but downstream users will need the README explanation to understand why one managed file remains.
