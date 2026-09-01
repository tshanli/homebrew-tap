class Upgit < Formula
  desc "Native & lightweight tool to upload any file to Github repository and get raw URL"
  homepage "https://github.com/pluveto/upgit"
  version "0.3.0"

  if OS.mac?
    if Hardware::CPU.arm?
      url "https://github.com/pluveto/upgit/releases/download/v#{version}/upgit_macos_arm64"
      sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
    else
      url "https://github.com/pluveto/upgit/releases/download/v#{version}/upgit_macos_amd64"
      sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
    end
  elsif OS.linux?
    if Hardware::CPU.arm?
      url "https://github.com/pluveto/upgit/releases/download/v#{version}/upgit_linux_arm64"
      sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
    else
      url "https://github.com/pluveto/upgit/releases/download/v#{version}/upgit_linux_amd64"
      sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
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
