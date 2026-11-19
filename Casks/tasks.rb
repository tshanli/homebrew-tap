cask "tasks" do
  version "15.14.1"

  on_arm do
    sha256 "74e1dbe1ceaf697dccaf7d0dc1995d93a0750523f9ea7b5d28d21e38068f2f03"

    url "https://github.com/tasks/tasks/releases/download/#{version}/tasks-org-#{version}-mac-aarch64.zip"
  end
  on_intel do
    sha256 "83bf235f5873a88e771fb29f89a1d7f489333d5b7896bf0c63694922bca76968"

    url "https://github.com/tasks/tasks/releases/download/#{version}/tasks-org-#{version}-mac-amd64.zip"
  end

  name "Tasks.org"
  desc "Open-source to-do list and task manager"
  homepage "https://tasks.org/"

  livecheck do
    url "https://github.com/tasks/tasks"
    strategy :github_latest
  end

  depends_on macos: :big_sur

  app "Tasks.org.app"

  zap trash: [
    "~/Library/Application Support/Tasks.org",
    "~/Library/Caches/org.tasks",
    "~/Library/Preferences/org.tasks.plist",
    "~/Library/Saved Application State/org.tasks.savedState",
  ]
end
