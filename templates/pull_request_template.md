<!-- coding-and-architecture-requirements:begin -->
<!-- source-repository: REPLACE_WITH_REPO_URL -->
<!-- version-pin: REPLACE_WITH_TAG_OR_COMMIT -->
<!-- canonical-entrypoint: REPLACE_WITH_TAGGED_STANDARDS_INDEX_URL -->
<!-- audit-manifest: REPLACE_WITH_AUDIT_MANIFEST_PATH -->
<!-- coding-and-architecture-requirements:end -->

# Pull Request Template

## Summary

Describe the behavior change and why it is needed.

## Standards impact

- [ ] Business logic still follows the intended functional core / imperative shell shape.
- [ ] New or changed pure/business logic has unit tests.
- [ ] Unit tests remain focused on one concern and use clear Arrange / Act / Assert structure.
- [ ] Any repo-specific exception has been recorded in `standards-overrides.md`.

## Verification

- [ ] Relevant tests ran
- [ ] Relevant lint/build/type checks ran
- [ ] Changed paths were validated manually when appropriate

## Risks

Document any residual risk, rollout concern, or follow-up work.
