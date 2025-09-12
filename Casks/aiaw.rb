cask "aiaw" do
  version "1.8.2"
  sha256 arm:   "be42953b1e53e7d122aa809b6d5ec404208126708e334a3362f723614aae3e54",
         intel: "1f6ac25540203a8d41fe3c21826d78d180a37d5b3603bb839ebbdf44d6d616dd"

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
