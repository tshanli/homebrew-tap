cask "kazumi" do
  version "2.1.8"
  sha256 "57820b5aa70b9249fdbc3bea5f623ebbd11d33dc2b80dd6a9378c7c4bad7dd43"

  url "https://github.com/Predidit/Kazumi/releases/download/#{version}/Kazumi_macos_#{version}.dmg"
  name "Kazumi"
  desc "Anime streaming application with custom rules and real-time super-resolution"
  homepage "https://github.com/Predidit/Kazumi"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "Kazumi.app"

  caveats do
    <<~EOS
      Kazumi may need to be allowed in System Settings → Privacy & Security.

      If you see "Kazumi is damaged and can't be opened" when launching the app,
      try reinstalling with the --no-quarantine flag:

        brew reinstall --cask --no-quarantine kazumi

      This bypasses macOS Gatekeeper quarantine for unsigned applications.
    EOS
  end

  zap trash: [
    "~/Library/Application Support/Kazumi",
    "~/Library/Caches/Kazumi",
    "~/Library/Logs/Kazumi",
    "~/Library/Preferences/com.predidit.kazumi.plist",
    "~/Library/Saved Application State/com.predidit.kazumi.savedState",
    "~/Library/WebKit/Kazumi",
  ]
end
