cask "kazumi" do
  version "1.8.4"
  sha256 "9b511e5ac39c5cee6fc3406e10946c53f93be995d8b0f070160a95002c72f457"

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
