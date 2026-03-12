# Lessons

## 2026-03-12

- What went wrong: A CLI surface cleanup was treated as finished before repo-wide references and breadcrumbs were fully audited.
- Preventive rule: After changing any downstream contract, run a full repo search for the old interface and add explicit audit-trail coverage before calling the change complete.
- Trigger signal: Any change that removes or reshapes install, update, or uninstall behavior.
