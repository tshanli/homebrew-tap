cask "aiaw" do
  version "1.7.8"
  sha256 arm:   "18b7fcf4539d7718f48d1c9386286a72a9e2c649f6a1ebb52f83ddd399f98dd9",
         intel: "1b1db6abc9f96835a6349e50abf29800d225e840b015408daed81afeb8af5ad8"

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
