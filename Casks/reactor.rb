cask "reactor" do
  version :latest
  sha256 :no_check

  url "https://github.com/farfary/Reactor/releases/latest/download/Reactor.dmg",
      verified: "github.com/farfary/Reactor/"
  name "Reactor"
  desc "macOS menubar system process monitor"
  homepage "https://github.com/farfary/Reactor"

  depends_on macos: ">= :monterey"

  app "Reactor.app"

  zap trash: [
    "~/Library/Preferences/com.reactor.app.plist",
    "~/Library/Application Support/Reactor",
    "~/Library/Logs/Reactor",
    "~/Library/Caches/com.reactor.app",
  ]
end
