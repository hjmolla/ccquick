cask "ccquick" do
  version "1.0.0"
  sha256 "917307c4f9b01a406c8a4ea8dc9864063e14be45593eaa57f79f242efdd79ff5"

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
