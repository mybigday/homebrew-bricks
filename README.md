# homebrew-bricks

Homebrew tap for [BRICKS](https://bricks.tools/) desktop apps.

```sh
brew tap mybigday/bricks
brew install --cask bricks-desktop-foundation
brew install --cask bricks-ctor
brew install --cask bricks-ctor-beta   # side-by-side with bricks-ctor
```

## Casks

| Cask | App | Channel | Arch |
|---|---|---|---|
| `bricks-desktop-foundation` | BRICKS Desktop Foundation | release | Apple Silicon + Intel |
| `bricks-ctor` | CTOR | release | Apple Silicon only |
| `bricks-ctor-beta` | CTOR Beta | beta | Apple Silicon only |

All three set `auto_updates true`: the in-app electron-updater is the primary
update path, and `brew upgrade --cask` is the fallback. The casks ship DMGs; the
ZIP artifacts exist only for the in-app updater.

### CTOR vs CTOR Beta

`bricks-ctor-beta` installs **side-by-side** with `bricks-ctor` — distinct app
bundle (`CTOR Beta.app`) and bundle id (`tools.bricks.project-desktop-beta`).

⚠️ **They share one data directory**, `~/.bricks-project-desktop` (sessions,
projects, settings). The path is hardcoded in the app, not derived from the
bundle id, so the release and beta builds read and write the same store. Because
of that:

- `brew uninstall --zap bricks-ctor` **does** remove `~/.bricks-project-desktop`.
- `brew uninstall --zap bricks-ctor-beta` **does not** — it only removes
  beta-namespaced files, so removing beta can never wipe the release install's
  data. (If you only ever ran beta, that directory is left behind by design.)
- Running both apps at the same time means two processes against the same store.

## How updates land

Sources are published to the BRICKS CDN by the monorepo's own release pipeline;
this tap only watches the canonical, CDN-served channels:

| Cask | Channel manifest |
|---|---|
| `bricks-desktop-foundation` | `https://cdn.bricks.tools/bricks-launcher/release/desktop/version.json` |
| `bricks-ctor` | `https://cdn.bricks.tools/bricks-project-desktop/release/version.json` |
| `bricks-ctor-beta` | `https://cdn.bricks.tools/bricks-project-desktop/beta/version.json` |

> The stable build is uploaded to a `prerelease/` path and **manually promoted**
> to `release/`; this tap intentionally tracks `release/` so it only follows
> promoted, shipped builds. Beta is published straight to `beta/`.

`.github/workflows/update-casks.yml` polls every 30 minutes (and on demand). For
each cask it runs `scripts/update-cask.rb`, which reads the cask's current
version and livecheck URL, compares against the channel manifest, and — when the
channel is ahead — downloads the DMG(s), recomputes `sha256`, rewrites the cask,
and opens a `chore(<cask>): update to <version>` PR. It refuses to downgrade and
fails loudly if a dual-arch cask is caught mid-publish with only one arch up.

`.github/workflows/audit.yml` runs on every PR that touches a cask:
`brew style`, `brew audit --cask --strict --online`, and a real
`brew install --cask` / `uninstall` on a macOS runner.

## Repo setup (one-time)

For the bot PRs to auto-merge after audit passes:

1. **Settings → General → Allow auto-merge.**
2. **Branch protection** on `main`: require the `audit` status check.
3. Add a **`TAP_PAT`** secret (a PAT or GitHub App token with `repo` +
   `workflow`). PRs opened with the default `GITHUB_TOKEN` don't trigger the
   audit workflow, so without `TAP_PAT` the bump PRs are opened for manual merge.

## Manual bump

```sh
ruby scripts/update-cask.rb Casks/bricks-ctor.rb   # prints new version if bumped
```
