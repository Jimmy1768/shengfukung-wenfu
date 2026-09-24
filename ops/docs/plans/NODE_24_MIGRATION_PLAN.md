# Node 20 → 24 migration, Wenfu Expo app

## Status

Draft. The Director started this work and set the target version; the steps
below are not implementation authority on their own.

- **Target version: 1.0.1.** Node 24 applies to runtime 1.0.1 and later only.
  Director, 2026-09-24.
- **Target Node: 24.21.0** — the machine's current default and the version
  DojoMate-Expo migrated to.
- Scope: `mobile/` only. Nothing in `rails/`, `vue/` or `ops/` changes.
- Reference: DojoMate-Expo migrated on 2026-09-24 and shipped a build.
  `~/Projects/DojoMate-Expo/docs/plans/NODE_24_MIGRATION_PLAN.md`. Read-only;
  nothing of theirs is modified, and nothing is copied that does not fit here.

## Why this is needed here

`mobile/eas.json` pins no Node version in any of its three profiles, and there
is no `.nvmrc`, `.node-version` or `engines` field. **EAS therefore chooses**,
and the choice is invisible until something breaks. The workspace record notes a
Golden-Template build where an unpinned profile silently picked 20.18.0 and
failed.

Meanwhile the machine's default `node` became 24.21.0 on 2026-09-23, so local
work and cloud builds have been on different major versions since then without
anything saying so.

## Baseline — Observed 2026-09-24

    main HEAD          dde3b3ed4adc7efea9017856892d07fe10c7b101
    main tree          9ae0788bb1c22e5abecd6cef1968646873ceeb45
                       7 commits ahead of origin/main, unpushed
    working tree       clean apart from two untracked ops/nginx/template/*.conf
                       files that are not mine
    yarn.lock sha256   87e7e9961748cb79d7039216eef05f828e309a04c728ce857ccc1e6d6ea91db6
    node_modules       present, installed under an unknown Node
    versioning.js      appVersion 1.0.0, iosBuildNumber 3, androidVersionCode 1
    local node         v24.21.0; node@20 20.20.2 still installed, not linked
    eas-cli            24.7.0, running on node-v24.21.0
    expo / RN          ~54.0.36 / 0.81.5
    Metro              not running; a peer session stopped it on 2026-09-24

**Build 3 ran on Node 20.19.4.** Read from its own EAS log rather than inferred:
`SPIN_UP_BUILDER` reports the VM template `macos-sequoia-15.6-xcode-26.0` with
`- Node.js 20.19.4`, and `INSTALL_CUSTOM_TOOLS` contains only its start and end
markers — no "Now using node" line, so nothing was pinned and the image default
was used. Build 3 is live on TestFlight.

## The constraint that shapes this plan

`app.config.js` sets `runtimeVersion: versioning.appVersion`. Runtime version is
therefore the app version, and **1.0.0 is already spent** on a Node 20 build that
is live.

If Node 24 were applied at 1.0.0, a Node 24 build and the live Node 20 build
would share OTA runtime `1.0.0`, and one OTA update would reach both
populations. Bumping to 1.0.1 puts Node 24 in its own runtime, so no OTA ever
spans two Node majors. That is why the version bump is a precondition and not
housekeeping.

## Non-goals

- No Expo SDK, React Native or dependency upgrade. Node is the only variable.
- No change to build 3, to anything published on runtime 1.0.0, or to
  `release/current`.
- No `engines` field in `package.json` and no new scripts.
- Not the Android lanes. `eas.json` still has no Android release profile, which
  `repo_context.md` records as a separate gap.

## Steps

**1. Bump the version. [DIRECTOR]**
`mobile/versioning.js` → `appVersion: '1.0.1'`. Version and build numbers are
the Director's. See the open decision on the build number below.

**2. Baseline the suite on Node 20, then on Node 24.**
Per shell, never a machine-wide relink — operator-kit requires Node >= 24:

    export PATH="/opt/homebrew/opt/node@20/bin:$PATH" && node -v

`rm -rf node_modules && yarn install --frozen-lockfile`, then `npm test` and
`npm run lint`; record exit codes and counts. Repeat on Node 24 and compare, and
confirm the `yarn.lock` hash above is unchanged. DojoMate saw first-run Jest
timeouts on both versions that passed on rerun; a single flake is not a finding.

**3. Pin, in one commit on a branch.**
`mobile/.nvmrc` = `24.21.0`, and `node: "24.21.0"` in every `eas.json` build
profile — development, testflight, production. Check the diff before committing:
in `eas.json`, only `node` lines may change.

`eas.json` is referenced by four files here — `__tests__/native-config.test.js`,
`scripts/verify-native-client.js`, `scripts/verify-ota-lane.js` and
`scripts/verify-release-interface.js` — so the suite must be green after the
edit, and any guardrail that asserts profile shape may need the new field
allowed.

**4. Prove it on EAS. [DIRECTOR]**
One `testflight` build from the branch. Confirm `Now using node v24.21.0` in
`INSTALL_CUSTOM_TOOLS` — the line whose absence identified build 3 as unpinned.
A `testflight` build exercises the production JS bundle, which the Android
development APK DojoMate used did not.

**5. Device smoke test.** Metro on Node 24 plus the Pixel or the iPhone.
Verification on hardware is the Director's, per the standing rule.

**6. Merge, push, and log the outcome here** with the build id and the Node line
from its log.

## Open decision

**The build number for 1.0.1.** Apple requires a build number unique within a
version, so 1.0.1 may restart at 1. DojoMate restarts per version — its record
reads "2.0.4 build 1" after "2.0.3 build 2". Continuing at 4 also works and
keeps a single ascending series. Either is safe; it is the Director's call, and
it is not decided here.

## Progress log

- **2026-09-24** — Plan written. Baseline captured. Build 3 confirmed as Node
  20.19.4 from its EAS log. Nothing changed in `mobile/`.
