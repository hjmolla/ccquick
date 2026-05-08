cask "ccquick" do
  version "1.1.0"
  sha256 "5c4e81c749e661cf1f41e79456793ff8f188f4cafc110153d3b1e02fcbfc8427"

  url "https://github.com/hyojoongit/ccquick/releases/download/v#{version}/CCQuick-#{version}.dmg"
  name "CCQuick"
  desc "Quick access to Claude Code from anywhere on your Mac"
  homepage "https://github.com/hyojoongit/ccquick"

  depends_on macos: ">= :sequoia"

  app "CCQuick.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/CCQuick.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Application Support/CCQuick",
    "~/Library/Preferences/com.ccquick.app.plist",
    "~/Library/LaunchAgents/com.ccquick.app.plist",
  ]
end
