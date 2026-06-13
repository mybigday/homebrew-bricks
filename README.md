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

## How releases & updates work

The BRICKS CDN serves **unversioned** DMG URLs (e.g. `CTOR-arm64.dmg`, overwritten
in place each release). Homebrew can't checksum-pin an unversioned URL, so instead
this tap **re-hosts each build as a versioned GitHub Release** and the casks
download from there with a pinned `sha256`:

- `url` → `https://github.com/mybigday/homebrew-bricks/releases/download/<cask>-<version>/<dmg>`
- `livecheck` → the CDN `version.json` (the source of truth for "is there a new build")

| Cask | livecheck channel (source) |
|---|---|
| `bricks-desktop-foundation` | `https://cdn.bricks.tools/bricks-launcher/release/desktop/version.json` |
| `bricks-ctor` | `https://cdn.bricks.tools/bricks-project-desktop/release/version.json` |
| `bricks-ctor-beta` | `https://cdn.bricks.tools/bricks-project-desktop/beta/version.json` |

> The stable build is uploaded to a `prerelease/` CDN path and **manually
> promoted** to `release/`; this tap tracks `release/` so it only follows promoted,
> shipped builds. Beta is published straight to `beta/`.

### Automation

`.github/workflows/update-casks.yml` polls every 30 minutes (and on demand). For
each cask it runs `scripts/update-cask.rb`, which:

1. reads the cask's current version + livecheck URL,
2. fetches the channel `version.json` and compares versions (refusing downgrades,
   and failing loudly if a dual-arch cask is mid-publish with only one arch up),
3. downloads the CDN DMG(s), computes `sha256`,
4. creates/uploads the `<cask>-<version>` GitHub Release (idempotent), and
5. rewrites `version` + `sha256` (the `url` is `#{version}`-interpolated) and opens
   a `chore(<cask>): update to <version>` PR.

`.github/workflows/audit.yml` runs on every cask PR: `brew style`,
`brew audit --cask --strict --online`, and a real `brew install --cask` /
`uninstall` on a macOS runner (the bump PR's release already exists, so the
install pulls the just-published DMG).

### Manual bump / re-host

```sh
export GH_REPO=mybigday/homebrew-bricks
ruby scripts/update-cask.rb Casks/bricks-ctor.rb          # bump if the channel is ahead
ruby scripts/update-cask.rb Casks/bricks-ctor.rb --force  # re-host the current version
```

`--force` skips the version check — used to seed the first release for a version
the cask already pins.
