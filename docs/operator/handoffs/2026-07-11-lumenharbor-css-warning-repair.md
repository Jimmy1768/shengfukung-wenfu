# LumenHarbor CSS Warning Repair Handoff

```yaml
handoff:
  handoff_id: wenfu-lumenharbor-css-warning-repair-2026-07-11
  source_control: Wenfu Control
  target_repo: /Users/jimmy1768/Projects/shengfukung-wenfu
  target_control: Wenfu Control
  objective: Repair the invalid LumenHarbor light-theme CSS rule so the Vue production build completes without the esbuild selector warning while preserving intended hero-copy contrast.
  accepted_design_refs:
    - /Users/jimmy1768/Projects/operator-kit/ops/docs/reference/codex_work_mode.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/acceptances/2026-07-11-repo-cleanup-integration-acceptance.md
    - /Users/jimmy1768/Projects/shengfukung-wenfu/vue/src/sourcegrid/templates/LumenHarbor.vue
  readiness_refs:
    - origin/main and local main at 34194796ffcb1ec24c3f88f0c562c2272753d4a1
    - Vue build warning: Expected identifier but found '[' near the mixed prefers-color-scheme and data-theme rule
  owned_files_or_surfaces:
    - vue/src/sourcegrid/templates/LumenHarbor.vue
    - docs/operator/handoffs/2026-07-11-lumenharbor-css-warning-repair.md
    - docs/operator/returns/2026-07-11-lumenharbor-css-warning-repair-return.md
  implementation_scope:
    - Confirm main is clean except this untracked Handoff file and still matches origin/main before edits.
    - Replace the invalid rule beginning with @media (prefers-color-scheme: light), [data-theme='golden-light'] with two valid CSS paths.
    - Under @media (prefers-color-scheme: light), apply color #f8fafc to .lumen-harbor .lh-hero-copy.
    - Outside the media query, apply the same color to [data-theme='golden-light'] .lumen-harbor .lh-hero-copy.
    - Preserve all other LumenHarbor layout, theme, copy, and responsive behavior.
    - Run the Vue production build and require the prior Expected identifier warning to be absent.
    - Inspect the generated CSS or build output to confirm both valid system-light and explicit golden-light paths are emitted.
    - Write the execution return and commit the Handoff, one-file CSS repair, and return record together on main.
    - Do not push; Wenfu Control will review the local commit first.
  blocked_surfaces:
    - files outside the three owned paths
    - unrelated CSS refactors or visual redesign
    - Rails, mobile, deploy, production/staging, secrets, billing, payments, and customer state
    - push and remote mutation
  required_checks:
    - git status --short --branch
    - rg confirms the invalid mixed media/selector expression is absent
    - npm run build from vue exits 0 with no Expected identifier warning
    - generated CSS contains a prefers-color-scheme light media rule and a golden-light LumenHarbor hero-copy selector
    - git diff --check
    - final git status --short --branch
  commit_required: true
  commit_message: Fix LumenHarbor light theme CSS
  codex_execution:
    profile_id: handoff_standard
    model: gpt-5.4
    reasoning: medium
  escalation_conditions:
    - starting dirty paths exist beyond this Handoff file
    - the valid split changes intended selectors after Vue scoped-style compilation
    - the Vue build fails or continues emitting the warning
    - repair requires touching a blocked surface
  return_shape:
    - status: complete | blocked
    - files_changed
    - exact_css_repair
    - commit_hash_and_subject
    - checks
    - final_git_status
    - blockers
```

## Readiness Decision

The malformed rule is at `vue/src/sourcegrid/templates/LumenHarbor.vue` around
line 676. CSS media-query lists may contain media conditions, not selectors.
Splitting the system preference and explicit theme selector preserves the
intended white hero-copy color and removes the parser warning without redesign.

## Return Location

`/Users/jimmy1768/Projects/shengfukung-wenfu/docs/operator/returns/2026-07-11-lumenharbor-css-warning-repair-return.md`

Return to Wenfu Control only. Do not dispatch another Handoff.
