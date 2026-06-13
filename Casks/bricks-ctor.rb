cask "bricks-ctor" do
  version "2.24.7"
  sha256 "43b954cc2cce8aa6e109c01f9107968245f536be9bcc968ab1b55093c8184b46"

  url "https://cdn.bricks.tools/bricks-project-desktop/release/CTOR-arm64.dmg"
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
  depends_on arch: :arm64

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
