cask "bricks-desktop-foundation" do
  arch arm: "arm64", intel: "x64"

  version "2.25.13"
  sha256 arm:   "ee136383bd509f2f50e3a679a3b4ae16c087031552133fa30852248feacbfbf5",
         intel: "9f796129b5adf71bc236e18b28c240dc8cca12ee4bbb9d527740d76c004b6b3f"

  # Per-version mirror of the CDN build (re-hosted so downloads stay checksum-pinned);
  # livecheck below tracks the CDN release channel as the source of truth.
  url "https://github.com/mybigday/homebrew-bricks/releases/download/bricks-desktop-foundation-#{version}/BRICKS-#{arch}.dmg"
  name "BRICKS Desktop Foundation"
  desc "BRICKS launcher and foundation runtime for desktop"
  homepage "https://bricks.tools/"

  livecheck do
    url "https://cdn.bricks.tools/bricks-launcher/release/desktop/version.json"
    strategy :json do |json|
      json["version"]
    end
  end

  auto_updates true
  depends_on macos: :monterey

  app "BRICKS Desktop Foundation.app"

  zap trash: [
    "~/Library/Application Support/BRICKS Desktop Foundation",
    "~/Library/Caches/tools.bricks.desktop-foundation",
    "~/Library/Caches/tools.bricks.desktop-foundation.ShipIt",
    "~/Library/Logs/BRICKS Desktop Foundation",
    "~/Library/Preferences/tools.bricks.desktop-foundation.plist",
    "~/Library/Saved Application State/tools.bricks.desktop-foundation.savedState",
  ]
end
