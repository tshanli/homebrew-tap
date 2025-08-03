cask "aiaw" do
  version "1.7.10"
  sha256 arm:   "20f1b99ab8e4bd275f8d2743f467651a704159b68f02897743d4d8e9084a5cfe",
         intel: "8ab2198031fedbfdde320fb04d93596f287474fa85ad4a5b8e1e19d02e9a1baa"

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
