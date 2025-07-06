class Upgit < Formula
  desc "Native & lightweight tool to upload any file to Github repository and get raw URL"
  homepage "https://github.com/pluveto/upgit"
  version "0.2.25"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/pluveto/upgit/releases/download/v#{version}/upgit_macos_arm64"
      sha256 "a9a9800690524b2cb918669417339f07a2a4182d634a182c75a948e52dd22d51"
    else
      url "https://github.com/pluveto/upgit/releases/download/v#{version}/upgit_macos_amd64"
      sha256 "f61ac4565f149057feb2441942ca982f36ff4769ebf84f91af3090981a95d710"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/pluveto/upgit/releases/download/v#{version}/upgit_linux_arm64"
      sha256 "29e51b7a9b23e66c8db9c75cefbe46ff1ec3cf06f3e86d60e9ce9514683837d8"
    else
      url "https://github.com/pluveto/upgit/releases/download/v#{version}/upgit_linux_amd64"
      sha256 "b102404040f9b37e63c29c42342c22eaa19cf21b8b9aef4c438f611dee485593"
    end
  end

  def install
    if OS.mac?
      if Hardware::CPU.arm?
        bin.install "upgit_macos_arm64" => "upgit"
      else
        bin.install "upgit_macos_amd64" => "upgit"
      end
    elsif OS.linux?
      if Hardware::CPU.arm?
        bin.install "upgit_linux_arm64" => "upgit"
      else
        bin.install "upgit_linux_amd64" => "upgit"
      end
    end
  end

  test do
    system "#{bin}/upgit", "--version"
  end
end
