cask "bricks-ctor" do
  version "2.24.13"
  sha256 "ca5160221b49d85058a214382290ba72988b0446db79e4396d678c4e94d9b727"

  # Per-version mirror of the CDN build (re-hosted so downloads stay checksum-pinned);
  # livecheck below tracks the CDN release channel as the source of truth.
  url "https://github.com/mybigday/homebrew-bricks/releases/download/bricks-ctor-#{version}/CTOR-arm64.dmg",
      verified: "github.com/mybigday/homebrew-bricks/"
  name "CTOR"
  desc "AI agent workspace for building BRICKS projects"
  homepage "https://docs.bricks.tools/ctor"

  livecheck do
    url "https://cdn.bricks.tools/bricks-project-desktop/release/version.json"
    strategy :json do |json|
      json["version"]
    end
  end

  auto_updates true
  depends_on arch: :arm64, macos: :monterey

  app "CTOR.app"

  # ~/.bricks-project-desktop holds all user data (sessions, projects, settings)
  # and is SHARED with bricks-ctor-beta — the data dir is hardcoded in the app,
  # not derived from the app id. Zapping the release cask removes it; the beta
  # cask deliberately leaves it alone so it can never destroy the release data.
  zap trash: [
    "~/.bricks-project-desktop",
    "~/Library/Application Support/CTOR",
    "~/Library/Caches/tools.bricks.project-desktop",
    "~/Library/Caches/tools.bricks.project-desktop.ShipIt",
    "~/Library/Logs/CTOR",
    "~/Library/Preferences/tools.bricks.project-desktop.plist",
    "~/Library/Saved Application State/tools.bricks.project-desktop.savedState",
  ]
end
