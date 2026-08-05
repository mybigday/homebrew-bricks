cask "bricks-desktop-foundation" do
  arch arm: "arm64", intel: "x64"

  version "2.25.1"
  sha256 arm:   "a6a34c8c426e91b83ae3ccbdca523be99f7eed33ff5bd93b9f8b4895c7a900b7",
         intel: "11b4380233dfcc7a1ded4152546bc2ee0d2d21889836700ff9918384cc29f46a"

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
