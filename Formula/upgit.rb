class Upgit < Formula
  desc "Native & lightweight tool to upload any file to Github repository and get raw URL"
  homepage "https://github.com/pluveto/upgit"
  version "0.3.0"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/pluveto/upgit/releases/download/v#{version}/upgit_macos_arm64.zip"
      sha256 "e02026c55ddfe8e7daa923fdb0f2dc9fa8b5e37bfd742b620988a5b6f3cdcdb9"
    else
      url "https://github.com/pluveto/upgit/releases/download/v#{version}/upgit_macos_amd64.zip"
      sha256 "f7ffb56570038914cbd10f57d847c10eda981692ff3712b1a099546b05d689a2"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/pluveto/upgit/releases/download/v#{version}/upgit_linux_arm64.zip"
      sha256 "ba0d6643b2e5d4465ebdb8ee474a11d930bad86ef0fe2b735a2077b57b05e20d"
    else
      url "https://github.com/pluveto/upgit/releases/download/v#{version}/upgit_linux_amd64.zip"
      sha256 "2300e70565b0b8b889be84872f7a8d1eb8122fd7013b472d81041bbb0f5224d8"
    end
  end

  def install
    # Each release asset is a zip holding the `upgit` binary, config.toml and recipes/
    bin.install "upgit"
  end

  test do
    system "#{bin}/upgit", "--version"
  end
end
