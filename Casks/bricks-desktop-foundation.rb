cask "bricks-desktop-foundation" do
  arch arm: "arm64", intel: "x64"

  version "2.24.11"
  sha256 arm:   "707d7e9cad0aba5c3cb217b5bd0af6cb63f673870d8c80812de0134943f5e0bf",
         intel: "10880a7369f26f30cd415c897d9386c8075c040cc63fee211dff9351126f13aa"

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
