cask "aiaw" do
  version "1.8.10"
  sha256 arm:   "aeb9a0fb9fbb1799bc7c14d41dbfaa43111106764881373d903cd987fc9d2720",
         intel: "e57aff35fa5269a014931e96553b3abe08f1197f73ee05ff5e7fca37d18305df"

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
