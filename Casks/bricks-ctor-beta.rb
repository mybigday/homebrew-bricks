cask "bricks-ctor-beta" do
  version "2.25.0-beta.56"
  sha256 "af30fb8d5165a6a77e2356a659369e80fe9048245c7fcdd15ead6d0c271745f0"

  # Per-version mirror of the CDN beta build (re-hosted so downloads stay checksum-pinned);
  # livecheck below tracks the CDN beta channel as the source of truth.
  url "https://github.com/mybigday/homebrew-bricks/releases/download/bricks-ctor-beta-#{version}/CTOR-Beta-arm64.dmg",
      verified: "github.com/mybigday/homebrew-bricks/"
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
  depends_on arch: :arm64, macos: :monterey

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
