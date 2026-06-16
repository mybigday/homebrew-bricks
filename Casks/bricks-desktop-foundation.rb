cask "bricks-desktop-foundation" do
  arch arm: "arm64", intel: "x64"

  version "2.24.8"
  sha256 arm:   "496409bb8d217ed1d02dc9ec98afba9c9e33d8de9aa25ef759d55e511fdd23d8",
         intel: "b8768644e436c1167f34c6572b3f0f1de78a054e57e31424d5bc14f4fd06c014"

  # Per-version mirror of the CDN build (re-hosted so downloads stay checksum-pinned);
  # livecheck below tracks the CDN release channel as the source of truth.
  url "https://github.com/mybigday/homebrew-bricks/releases/download/bricks-desktop-foundation-#{version}/BRICKS-#{arch}.dmg",
      verified: "github.com/mybigday/homebrew-bricks/"
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
