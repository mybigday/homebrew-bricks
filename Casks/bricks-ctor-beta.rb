cask "bricks-ctor-beta" do
  version "2.25.0-beta.42"
  sha256 "6a9866fa28caf2d45bd275382f4c2f79c82c8145edde031f912da2a2d56535af"

  url "https://cdn.bricks.tools/bricks-project-desktop/beta/CTOR-Beta-arm64.dmg"
  name "CTOR Beta"
  desc "AI agent workspace for building BRICKS projects (beta channel)"
  homepage "https://docs.bricks.tools/ctor"

  livecheck do
    url "https://cdn.bricks.tools/bricks-project-desktop/beta/version.json"
    strategy :json do |json|
      json["version"]
    end
  end

  auto_updates true
  depends_on arch: :arm64

  app "CTOR Beta.app"

  # CTOR Beta installs side-by-side with bricks-ctor (distinct app bundle + app id)
  # but SHARES the ~/.bricks-project-desktop data dir with it. That dir is
  # intentionally omitted below so uninstalling beta never deletes the release
  # install's sessions/projects/settings. Only beta-namespaced paths are zapped.
  zap trash: [
    "~/Library/Application Support/CTOR Beta",
    "~/Library/Caches/tools.bricks.project-desktop-beta",
    "~/Library/Caches/tools.bricks.project-desktop-beta.ShipIt",
    "~/Library/Logs/CTOR Beta",
    "~/Library/Preferences/tools.bricks.project-desktop-beta.plist",
    "~/Library/Saved Application State/tools.bricks.project-desktop-beta.savedState",
  ]
end
