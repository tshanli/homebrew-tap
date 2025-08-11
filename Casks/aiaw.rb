cask "aiaw" do
  version "1.7.11"
  sha256 arm:   "5d082be94310bd06fdb7a6f197b301f505866a8ccdb66ff51775451159412291",
         intel: "ebacb1eae52b6b55d053690dd15de1b22d15b0f2e882534177e45b3cc21bb5aa"

  url "https://github.com/NitroRCr/AIaW/releases/download/v#{version}/AI.as.Workspace_#{version}_#{Hardware::CPU.intel? ? "x64" : "aarch64"}.dmg"
  name "AI as Workspace"
  name "AIaW"
  desc "Elegant AI chat client with multiple workspaces, plugin system, and cross-platform support"
  homepage "https://github.com/NitroRCr/AIaW"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "AI as Workspace.app"

  caveats do
    <<~EOS
      If you see "AI as Workspace is damaged and can't be opened" when launching the app,
      try reinstalling with the --no-quarantine flag:

        brew reinstall --cask --no-quarantine aiaw

      This bypasses macOS Gatekeeper quarantine for unsigned applications.
    EOS
  end

  zap trash: [
    "~/Library/Application Support/AI as Workspace",
    "~/Library/Caches/AI as Workspace",
    "~/Library/Logs/AI as Workspace",
    "~/Library/Preferences/com.aiaw.app.plist",
    "~/Library/Saved Application State/com.aiaw.app.savedState",
    "~/Library/WebKit/AI as Workspace",
  ]
end
