cask "opentrack" do
  version "6.0.0"
  sha256 "02c46b1d0bb092052c63836ba535756223ac8d7d88bbb741531cd8f4ec6750fa"

  url "https://github.com/bircni/aitrack/releases/download/v#{version}/opentrack_#{version}_aarch64.dmg"
  name "opentrack"
  desc "Menu bar app tracking Claude Code and Codex usage limits and cost"
  homepage "https://github.com/bircni/aitrack"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :ventura

  app "opentrack.app"

  caveats do
    <<~EOS
      opentrack is ad-hoc signed and not notarized by Apple, so macOS may block it
      on first launch. Allow it in System Settings → Privacy & Security → Open Anyway,
      or remove the quarantine attribute:

        xattr -dr com.apple.quarantine /Applications/opentrack.app
    EOS
  end

  zap trash: [
    "~/Library/Application Support/dev.bircni.opentrack",
    "~/Library/Caches/dev.bircni.opentrack",
    "~/Library/Preferences/dev.bircni.opentrack.plist",
    "~/Library/Saved Application State/dev.bircni.opentrack.savedState",
    "~/Library/WebKit/dev.bircni.opentrack",
  ]
end
