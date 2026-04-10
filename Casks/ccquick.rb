cask "ccquick" do
  version "1.0.1"
  sha256 "b6bf4d0bac857d200575f91bbf808132e688e6a2dc59e1e392436e237388b364"

  url "https://github.com/hyojoongit/ccquick/releases/download/v#{version}/CCQuick-#{version}.dmg"
  name "CCQuick"
  desc "Quick access to Claude Code from anywhere on your Mac"
  homepage "https://github.com/hyojoongit/ccquick"

  depends_on macos: ">= :sequoia"

  app "CCQuick.app"

  zap trash: [
    "~/Library/Application Support/CCQuick",
    "~/Library/Preferences/com.ccquick.app.plist",
    "~/Library/LaunchAgents/com.ccquick.app.plist",
  ]
end
