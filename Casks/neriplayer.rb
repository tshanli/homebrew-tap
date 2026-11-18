cask "neriplayer" do
  # Upstream tags each release `NeriPlayer-<build>`, so the tag is the version.
  version "NeriPlayer-af3c1b0.11151911"

  on_arm do
    sha256 "9cf998fff518a7f43badd3635233a4d80a11e10a28819f530455e1387081a573"

    url "https://github.com/cwuom/NeriPlayer-Desktop/releases/download/#{version}/NeriPlayer_1.0.0_aarch64-adhoc.dmg"
  end
  on_intel do
    sha256 "0e41968f64e2c45960a52947fee8fe5e065c7abecdcc1508eca23b968ef37720"

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
