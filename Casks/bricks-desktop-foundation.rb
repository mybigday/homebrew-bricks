cask "bricks-desktop-foundation" do
  arch arm: "arm64", intel: "x64"

  version "2.25.2"
  sha256 arm:   "873d0f7af0b4bab9ca5ef4adf64a2ef70fc8958a6591e1789ecad4adbee39c9f",
         intel: "bf6a098f0d6729567e08efaa28580b5c5961117b6a27b4574552e3ab3f679767"

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
