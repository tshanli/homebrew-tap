class SourcegitDevelop < Formula
  desc 'Open-source Git GUI client (develop branch build)'
  homepage 'https://github.com/sourcegit-scm/sourcegit'
  url 'https://github.com/sourcegit-scm/sourcegit/archive/refs/heads/develop.zip'
  version '20260112-af1363e'

  depends_on 'dotnet'
  depends_on 'openssl@3'

  def install
    # Use static version string for Homebrew build - updated by GitHub Action
    commit_hash = 'af1363e'

    # Build and publish
    system 'dotnet', 'build', '-c', 'Release'
    system 'dotnet', 'publish', 'src/SourceGit.csproj', '-c', 'Release',
           '-o', 'build/SourceGit', '-r', 'osx-arm64', '--self-contained', 'true'

    # Create app bundle following your package script
    cd 'build' do
      mkdir_p 'SourceGit.app/Contents/Resources'
      mv 'SourceGit', 'SourceGit.app/Contents/MacOS'
      cp 'resources/app/App.icns', 'SourceGit.app/Contents/Resources/App.icns'

      # Create Info.plist with version substitution
      inreplace 'resources/app/App.plist', 'SOURCE_GIT_VERSION', commit_hash
      cp 'resources/app/App.plist', 'SourceGit.app/Contents/Info.plist'

      # Remove debug symbols
      rm_rf 'SourceGit.app/Contents/MacOS/SourceGit.dsym'
    end

    # Install the app bundle
    prefix.install 'build/SourceGit.app'
  end

  def caveats
    <<~EOS
      To use SourceGit from your Applications folder, run:
        ln -sf "[36m#{opt_prefix}/SourceGit.app[0m" "$HOME/Applications/SourceGit.app"
    EOS
  end
end
