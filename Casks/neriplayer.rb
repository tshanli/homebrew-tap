cask "neriplayer" do
  # Upstream tags each release `NeriPlayer-<build>`, so the tag is the version.
  version "NeriPlayer-18744b1.11211334"

  on_arm do
    sha256 "8ee42249f6a0acc33e06ac7df935cba4cabe89ff83abb8d27f424e0c31a46b17"

    url "https://github.com/cwuom/NeriPlayer-Desktop/releases/download/#{version}/NeriPlayer_1.0.0_aarch64-adhoc.dmg"
  end
  on_intel do
    sha256 "6f7025e32eb2a8778663b9ad41591571f413c18cf628280348c88301005e3e4d"

    url "https://github.com/cwuom/NeriPlayer-Desktop/releases/download/#{version}/NeriPlayer_1.0.0_x64-adhoc.dmg"
  end

  name "NeriPlayer"
  desc "Multi-source streaming, local music management and word-synced lyrics player"
  homepage "https://github.com/cwuom/NeriPlayer-Desktop"

  livecheck do
    url :url
    regex(/^(NeriPlayer-\h+\.\d+)$/i)
    strategy :github_latest
  end

  depends_on macos: :big_sur

  app "NeriPlayer.app"

  caveats do
    <<~EOS
      NeriPlayer is ad-hoc signed and not notarized by Apple, so macOS may block it
      on first launch. Allow it in System Settings → Privacy & Security → Open Anyway,
      or remove the quarantine attribute:

        xattr -dr com.apple.quarantine /Applications/NeriPlayer.app
    EOS
  end

  zap trash: [
    "~/Library/Application Support/moe.ouom.neriplayer.desktop",
    "~/Library/Caches/moe.ouom.neriplayer.desktop",
    "~/Library/Preferences/moe.ouom.neriplayer.desktop.plist",
    "~/Library/Saved Application State/moe.ouom.neriplayer.desktop.savedState",
    "~/Library/WebKit/moe.ouom.neriplayer.desktop",
  ]
end
