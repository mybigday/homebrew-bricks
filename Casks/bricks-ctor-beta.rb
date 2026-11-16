cask "bricks-ctor-beta" do
  version "2.26.0-beta.38"
  sha256 "e933e40eee4ead77de815f3ef8467ebd0d103e4147f4cf128137b9d966e6b355"

  # Per-version mirror of the CDN beta build (re-hosted so downloads stay checksum-pinned);
  # livecheck below tracks the CDN beta channel as the source of truth.
  url "https://github.com/mybigday/homebrew-bricks/releases/download/bricks-ctor-beta-#{version}/CTOR-Beta-arm64.dmg"
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
