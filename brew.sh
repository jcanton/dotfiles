#!/usr/bin/env bash

# Install command-line tools using Homebrew.

# Make sure we’re using the latest Homebrew.
brew update

# Upgrade any already-installed formulae.
brew upgrade

# Save Homebrew’s installed location.
BREW_PREFIX=$(brew --prefix)

# Install GNU core utilities (those that come with macOS are outdated).
# Don’t forget to add `$(brew --prefix coreutils)/libexec/gnubin` to `$PATH`.
brew install coreutils
ln -s "${BREW_PREFIX}/bin/gsha256sum" "${BREW_PREFIX}/bin/sha256sum"

# Install some other useful utilities like `sponge`.
brew install moreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, `g`-prefixed.
brew install findutils
# Install GNU `sed`, overwriting the built-in `sed`.
brew install gnu-sed --with-default-names
# Install a modern version of Bash.
brew install bash
brew install bash-completion2

# Switch to using brew-installed bash as default shell
if ! fgrep -q "${BREW_PREFIX}/bin/bash" /etc/shells; then
  echo "${BREW_PREFIX}/bin/bash" | sudo tee -a /etc/shells;
  chsh -s "${BREW_PREFIX}/bin/bash";
fi;

# Install `wget` with IRI support.
brew install wget --with-iri

# Install GnuPG to enable PGP-signing commits.
brew install gnupg

# Install more recent versions of some macOS tools.
brew install vim --with-override-system-vi
brew install neovim
brew install grep
brew install openssh
brew install tmux
brew install php
brew install gmp
brew install ripgrep
brew install node
brew install ccls

# Install font tools.
#brew tap bramstein/webfonttools
#brew install sfnt2woff
#brew install sfnt2woff-zopfli
#brew install woff2
brew tap homebrew/cask-fonts
brew install --cask font-blex-mono-nerd-font

# Install other useful binaries.
brew install ack
#brew install exiv2
brew install ffmpeg
brew install gcc
brew install git
brew install git-lfs
brew install gs
brew install htop
brew install imagemagick --with-webp
brew install lua
#brew install lynx
brew install ncview
brew install obsidian
#brew install p7zip
#brew install pigz
#brew install pv
brew install rename
brew install rlwrap
brew install ssh-copy-id
brew install tree
brew install vbindiff
#brew install zopfli
brew install wget

brew install --cask flux
brew install --cask freecad
brew install --cask maccy
brew install --cask mactex-no-gui
brew install --cask monitorcontrol
brew install --cask skim

# Remove outdated versions from the cellar.
brew cleanup
