# Node 20 → 24 migration, Wenfu Expo app

## Status

Draft. The Director started this work and set the target version; the steps
below are not implementation authority on their own.

- **Version stays 1.0.0. Next iOS build is 4, on the `production` profile.**
  Director, 2026-09-24. Not `testflight` — that lane has served its purpose.
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

## The runtime question, and why the channel settles it

`app.config.js` sets `runtimeVersion: versioning.appVersion`, so runtime is the
app version and **1.0.0 already carries three finished iOS builds** — 1, 2 and 3
— all built on Node 20, plus ten OTA updates on the `testflight` channel.

The concern was that a Node 24 build joining runtime 1.0.0 would share OTA
traffic with Node 20 builds, in both directions: a Node 24 bundle reaching the
staff member on build 2, and — the likelier one — a fresh build 4 pulling the
newest existing Node 20 bundle on first launch.

**The `production` profile removes it.** Observed 2026-09-24:
`eas channel:view production` returns "Could not find channel", so the channel
does not exist and has never received an update. Build 4 therefore starts with
no OTA history and cannot pull a Node 20 bundle, and the `testflight` population
cannot receive anything published to `production`. Runtime is shared; the
channel is not, and the channel is what routes updates.

So no version bump is needed. The two Node majors are separated by channel
rather than by version, which costs nothing and spends no version number.

What remains, and it is a discipline rather than a defect: **do not publish the
same OTA to both channels** while the two Node majors coexist. That is the only
path by which they could still mix.

Two consequences worth stating:

- This is also **the first `production`-profile build this project has made**.
  It proves the production lane as well as Node 24.
- `production` is `distribution: store`. Building is not submitting, and an
  App Store submission is a separate decision — it would also produce the
  public listing that the mobile-web fork's bucket 2 currently lacks.

## Non-goals

- No Expo SDK, React Native or dependency upgrade. Node is the only variable.
- No change to build 3, to anything published on runtime 1.0.0, or to
  `release/current`.
- No `engines` field in `package.json` and no new scripts.
- Not the Android lanes. `eas.json` still has no Android release profile, which
  `repo_context.md` records as a separate gap.

## Steps

**1. Bump the build number. [DIRECTOR]**
`mobile/versioning.js` → `iosBuildNumber: '4'`. `appVersion` stays `1.0.0`.
Build 3 is spent: it is finished, submitted, and live on TestFlight.

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
One `production` build from the branch — `npm run build:production`. Confirm
`Now using node v24.21.0` in `INSTALL_CUSTOM_TOOLS`, the line whose absence
identified build 3 as unpinned. A store build exercises the production JS
bundle, which the Android development APK DojoMate used did not.

**5. Device smoke test.** Metro on Node 24 plus the Pixel or the iPhone.
Verification on hardware is the Director's, per the standing rule.

**6. Merge, push, and log the outcome here** with the build id and the Node line
from its log.

## Decided

- Version stays **1.0.0**; next iOS build is **4**. Google has never received an
  upload, so no Android version code is consumed, and the iOS version does not
  need to move because the channel separates the Node majors.
- Validation build uses the **`production`** profile.

## Progress log

- **2026-09-24** — Plan written. Baseline captured. Build 3 confirmed as Node
  20.19.4 from its EAS log. Nothing changed in `mobile/`.
- **2026-09-24** — Director set the target: stay on 1.0.0, iOS build 4,
  `production` profile. An earlier revision of this plan proposed 1.0.1 to keep
  the Node majors apart; the `production` channel does the same job for nothing,
  and the version bump was dropped.
