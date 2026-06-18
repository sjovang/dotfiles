#!/bin/zsh

# Install xcode CLI tools (pre-req for homebrew)
if xcode-select -p 2>&1 | grep -q "error: Unable to get active developer"; then
  echo "xcode command line tools is required for homebrew. installing …"
  echo "This installer will open a UI window to proceed"
  xcode-select --install
fi

# Install Homebrew (https://brew.sh)
if ! command -v brew &> /dev/null; then
  echo "Homebrew is missing. installing …"

  if ! sudo -n true 2>/dev/null; then
    echo "Sudo privileges are required to install Homebrew."
    echo "Please enter your administrator password below:"
    sudo -v || { echo "Incorrect password or missing sudo access. Aborting."; exit 1; }
  fi
  
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" "" 
  
  if [ -f "/opt/homebrew/bin/brew" ]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> /Users/tjs/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

if [ -f "/opt/homebrew/bin/brew" ]; then
  if [ ! -f "/opt/homebrew/bin/chezmoi" ]; then
    /opt/homebrew/bin/brew install chezmoi
  fi
fi

# Create SSH Key
while true; do
    echo "Create passhrase for ssh key"
    print -n "Enter passphrase: "
    read -s pass1; echo ""
    print -n "Repeat passphrase: "
    read -s pass2; echo ""   
    if [ "$pass1" = "$pass2" ]; then
        ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "$pass1" -q
        unset pass1 pass2
        echo "key created in ~/.ssh/id_ed25519"
        break
    else
        echo "The passphrases was not equal. Try again"
        echo ""
    fi
done

# Initialize dotfiles with chezmoi
if [ ! -d "~/.local/share/chezmoi" ]; then
  chezmoi init https://codeberg.org/liasis/dotfiles.git
fi
